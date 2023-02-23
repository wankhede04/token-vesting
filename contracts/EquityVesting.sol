// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract EquityVesting is AccessControl {
    struct Equity {
        uint256 vestingAmount;
        uint256 percentRelease;
        uint256 distributionInterval;
    }
    struct Employee {
        bytes4 class;
        uint256 amountClaimed;
        uint256 vestingCliff;
        uint256 lastUpdated;
    }

    bytes4 public constant CXO = bytes4(keccak256(abi.encodePacked("CXO")));
    bytes4 public constant SENIOR_MANAGER =
        bytes4(keccak256(abi.encodePacked("SENIOR_MANAGER")));
    bytes4 public constant OTHER = bytes4(keccak256(abi.encodePacked("OTHER")));
    uint256 public constant PERCENT_BASE = 10000;

    mapping(bytes4 => Equity) public equityByClass;
    mapping(address => Employee) public employeeDetails;
    IERC20Metadata public equityToken;

    event EmployeeAdded(
        address[] recipients,
        bytes4[] recipientClass,
        uint256 vestingCliff
    );

    constructor(IERC20Metadata _equityToken, address _admin) {
        equityToken = _equityToken;
        uint256 tokenDecimalPrecision = 10 ** _equityToken.decimals();
        _updateEquity(Equity(1000 * tokenDecimalPrecision, 2500, 365 days), CXO);
        _updateEquity(Equity(800 * tokenDecimalPrecision, 2500, 365 days), SENIOR_MANAGER);
        _updateEquity(Equity(400 * tokenDecimalPrecision, 5000, 365 days), OTHER);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function addEmployees(
        address[] memory _recipients,
        bytes4[] memory _recipientClass
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _recipients.length == _recipientClass.length,
            "EquityVesting: invalid array data"
        );
        uint256 totalRecipients = _recipients.length;
        uint256 currentTimestamp = block.timestamp;
        uint256 year = 365 days;
        for (uint256 index = 0; index < totalRecipients; index++) {
            employeeDetails[_recipients[index]] = Employee(
                _recipientClass[index],
                0,
                currentTimestamp + year,
                currentTimestamp
            );
        }
        emit EmployeeAdded(
            _recipients,
            _recipientClass,
            currentTimestamp + year
        );
    }

    function claimEquity() external returns (uint256 amount) {
        address recipient = _msgSender();
        uint256 interval;
        (amount, interval) = getEquityToClaim(recipient);
        require(amount != 0, "EquityVesting: zero amount to claim");

        Employee storage employee = employeeDetails[recipient];
        employee.lastUpdated += interval;
        employee.amountClaimed += amount;
        equityToken.transfer(recipient, amount);
    }

    function getEquityToClaim(address recipient)
        public
        view
        returns (uint256 amount, uint256 interval)
    {
        uint256 currentTimestamp = block.timestamp;
        Employee memory employee = employeeDetails[recipient];
        Equity memory equity = equityByClass[employee.class];
        // If Employee.vestingCliff == Equity.distributionInterval, this check is irrelevant.
        // For Employee.amountClaimed == Equity.vestingAmount, employee claimed total vesting
        if (
            currentTimestamp < employee.vestingCliff ||
            employee.amountClaimed == equity.vestingAmount
        ) {
            return (0, equity.distributionInterval);
        }

        if (
            currentTimestamp >
            equity.distributionInterval + employee.lastUpdated
        ) {
            uint256 unclaimedCount = (currentTimestamp -
                employee.lastUpdated) / equity.distributionInterval;
            amount =
                (equity.vestingAmount *
                    (equity.percentRelease * unclaimedCount)) /
                PERCENT_BASE;
            interval = equity.distributionInterval;
        }
    }

    function _updateEquity(Equity memory _equity, bytes4 class) private {
        equityByClass[class] = _equity;
    }
}
