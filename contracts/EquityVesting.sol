// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import { IERC20Metadata } from "node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract EquityVesting {
    struct Equity {
        uint256 totalAmount;
        uint256 percentRelease;
        uint256 distributionInterval;
    }

    // Generated using bytes4(keccak256(abi.encodePacked("Order")))
    bytes4 public constant CXO = bytes4(keccak256(abi.encodePacked("CXO")));
    // Generated using bytes4(keccak256(abi.encodePacked("StopLossLimitOrder")))
    bytes4 public constant SENIOR_MANAGER = bytes4(keccak256(abi.encodePacked("SENIOR_MANAGER")));
    // Generated using bytes4(keccak256(abi.encodePacked("TakeProfitLimitOrder")))
    bytes4 public constant OTHER = bytes4(keccak256(abi.encodePacked("OTHER")));
    uint256 public constant PERCENT_BASE = 10000;

    mapping(bytes4 => Equity) public equityByClass;
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

    function _updateEquity(Equity memory _equity, bytes4 class) private {
        equityByClass[class] = _equity;
    }
}
