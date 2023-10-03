// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    function setUp() public {
        counter = new Counter();
        counter.setNumber(0);
        counter.packValues(12, 14);
    }

    function test_Increment() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }

    function testSetSlotValues() public {
        counter.packValues(12, 14);
    }

    function testSlotValues() public {
        bytes32 res = vm.load(address(counter), bytes32(uint256(1)));
        // assertEq(
        //     abi.encodePacked(counter.a() + counter.b()),
        //     abi.encodePacked(counter.a(), res_a)
        // );
        uint128 a;
        uint256 b;
        a = uint128(uint256(res));
        b = uint128(uint256(res) >> 128);
        console2.logUint(a);
        console2.logUint(b);
        assertEq(counter.b(), b);
        assertEq(counter.a(), a);
    }
}
