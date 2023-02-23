// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title EquityVesting contract
 * @author [wankhede04]
 *
 * @dev Claim equity tokens according to vesting period of a user
 */
contract EquityVesting is AccessControl {
    struct EquityClass {
        uint256 vestingAmount;
        uint256 releaseRate;
        uint256 cliffDuration;
        uint256 distributionInterval;
    }
    struct EmployeeDetail {
        bytes32 class;
        uint256 amountClaimed;
        uint256 lastUpdated;
    }

    // convert to seconds, 31536000
    uint256 private constant _YEAR = 365 days;
    // keccak256("CXO")
    bytes32 private constant CXO =
        0xb7f414843e68da0b34c0fe72d1e077bca7ad8d815444157b9e3e6ccc0d4f0b68;
    // keccak256("SENIOR_MANAGER")
    bytes32 private constant SENIOR_MANAGER =
        0xd3d780eaccdeb67c1d22abd19ec5480ce7d3f8b12b05d8346b4a7b5d8a14a8ad;
    // keccak256("OTHER")
    bytes32 private constant OTHER =
        0x35b65de3b579a9ce74763d33e74f08dcef72a66ee55fd214549ace2be760d16d;
    // Used to keep the division ratio of EquityClass.releaseRate
    uint256 public constant PERCENT_BASE = 10000;
    // Store equity class details by class {CXO, SENIOR_MANAGER, OTHER}
    mapping(bytes32 => EquityClass) public equityByClass;
    // Store employee details by employee address
    mapping(address => EmployeeDetail) public employeeDetails;
    // Interfaced address of claiming token
    IERC20 public equityToken;

    event EmployeeAdded(
        address[] recipients,
        bytes32[] recipientClass,
        uint256 vestingCliff
    );
    event EquityClaimed(
        address indexed recipient,
        uint256 claimAmount,
        uint256 nextUnlock
    );

    /**
     * @dev Sets equity token, grant admin role and add equity classes
     *
     * @param _equityToken Address of claiming token
     * @param _admin Address of default admin
     */
    constructor(IERC20 _equityToken, address _admin) {
        equityToken = _equityToken;

        _createEquityClass(
            EquityClass(1000000000000000000000, 2500, _YEAR, _YEAR),
            CXO
        );
        _createEquityClass(
            EquityClass(800000000000000000000, 2500, _YEAR, _YEAR),
            SENIOR_MANAGER
        );
        _createEquityClass(
            EquityClass(400000000000000000000, 5000, _YEAR, _YEAR),
            OTHER
        );
        // Note: We can add more roles to increase security, if required
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * @dev Add equity class. Should accessed by default admin only
     *
     * @param _equity Var of EquityClass struct
     * @param _class keccack value of string class
     */
    function createEquityClass(EquityClass memory _equity, bytes32 _class)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _createEquityClass(_equity, _class);
    }

    /**
     * @dev Add batch employees with their respective class
     * - Should accessed by default admin only
     *
     * @param _recipients Array of address of employees
     * @param _recipientClass Array of hashed(keccak) of class string
     */
    function addEmployees(
        address[] memory _recipients,
        bytes32[] memory _recipientClass
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 totalRecipients = _recipients.length;
        require(
            totalRecipients == _recipientClass.length,
            "EquityVesting: invalid array data"
        );

        uint256 currentTimestamp = block.timestamp;
        for (uint256 index = 0; index < totalRecipients; index++) {
            employeeDetails[_recipients[index]] = EmployeeDetail(
                _recipientClass[index],
                0,
                currentTimestamp
            );
        }
        emit EmployeeAdded(
            _recipients,
            _recipientClass,
            currentTimestamp + _YEAR
        );
    }

    /**
     * @dev Employees can claim equity after tokens are unlocked
     */
    function claimEquity() external returns (uint256 amount) {
        address recipient = _msgSender();
        uint256 interval;
        (amount, interval) = getEquityToClaim(recipient);
        require(amount != 0, "EquityVesting: zero amount to claim");

        EmployeeDetail storage employee = employeeDetails[recipient];
        employee.lastUpdated += interval;
        employee.amountClaimed += amount;
        equityToken.transfer(recipient, amount);
        emit EquityClaimed(recipient, amount, employee.lastUpdated + _YEAR);
    }

    /**
     * @dev Calculate equity to claim as per vesting cliff and interval of unlock
     *
     * @param _recipient Address of employee
     */
    function getEquityToClaim(address _recipient)
        public
        view
        returns (uint256 amount, uint256 interval)
    {
        uint256 currentTimestamp = block.timestamp;
        EmployeeDetail memory employee = employeeDetails[_recipient];
        EquityClass memory equity = equityByClass[employee.class];

        // For EmployeeDetail.amountClaimed == EquityClass.vestingAmount, employee claimed total vesting
        if (
            currentTimestamp < (employee.lastUpdated + equity.cliffDuration) ||
            employee.amountClaimed == equity.vestingAmount
        ) {
            return (0, equity.distributionInterval);
        }

        if (
            currentTimestamp >
            equity.distributionInterval + employee.lastUpdated
        ) {
            uint256 unclaimedCount = (currentTimestamp - employee.lastUpdated) /
                equity.distributionInterval;
            amount =
                (equity.vestingAmount * (equity.releaseRate * unclaimedCount)) /
                PERCENT_BASE;
            interval = equity.distributionInterval;
        }
    }

    function _createEquityClass(EquityClass memory _equity, bytes32 class)
        private
    {
        equityByClass[class] = _equity;
    }
}
