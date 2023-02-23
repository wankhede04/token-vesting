// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract EquityVesting {
    struct Equity {
        uint256 vestingAmount;
        uint256 percentRelease;
        uint256 distributionInterval;
    }

    bytes4 public constant CXO = bytes4(keccak256(abi.encodePacked("CXO")));
    bytes4 public constant SENIOR_MANAGER = bytes4(keccak256(abi.encodePacked("SENIOR_MANAGER")));
    bytes4 public constant OTHER = bytes4(keccak256(abi.encodePacked("OTHER")));
    uint256 public constant PERCENT_BASE = 10000;
    uint256 public constant VESTING_CLIFF = 356 days;

    mapping(bytes4 => Equity) public equityByClass;
    mapping(address => bytes4) public classOfEmployee;
    IERC20Metadata public equityToken;

    constructor(IERC20Metadata _equityToken) {
        equityToken = _equityToken;
        _updateEquity(Equity(
            1000,
            2500,
            365 days
        ), CXO);
        _updateEquity(Equity(
            800,
            2500,
            365 days
        ), SENIOR_MANAGER);
        _updateEquity(Equity(
            400,
            5000,
            365 days
        ), OTHER);
    }

    function addEmployees(address[] memory recipients, bytes4[] memory recipientClass) external {
        // TODO: add access to admin
        require(recipients.length == recipientClass.length, "EquityVesting: invalid array data");
        uint256 totalRecipients = recipients.length;
        for (uint256 index = 0; index < totalRecipients; index++) {
            classOfEmployee[recipients[index]] = recipientClass[index];
        }
        // TODO: add event
    }

    function _updateEquity(Equity memory _equity, bytes4 class) private {
        equityByClass[class] = _equity;
    }
}
