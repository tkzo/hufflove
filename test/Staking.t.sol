// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

interface Staking {
    function balanceOf(address) external returns (uint256);
}

contract StakingTest is Test {
    /// @dev Address of the Staking contract.
    Staking public staking;

    /// @dev Setup the testing environment.
    function setUp() public {
        staking = Staking(HuffDeployer.deploy("Staking"));
    }

    /// @dev Ensure that you can set and get the value.
    function testBalanceOf() public {
        uint256 balance = staking.balanceOf(address(this));
        assertEq(balance, 0);
    }
}
