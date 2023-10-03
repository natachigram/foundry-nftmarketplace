// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    uint256 public number;
    uint128 public a;
    uint128 public b;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }

    function packValues(uint128 _a, uint128 _b) public {
        a = _a;
        b = _b;
    }
}
