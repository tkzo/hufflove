// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "solidity/Mock20.sol";

interface Mini {
    function REWARDS_TOKEN() external view returns (address);

    function STAKING_TOKEN() external view returns (address);
}

contract MiniTest is Test {
    Mini public mini;
    Mock20 public rewardToken;

    string public constant REWARD_NAME = "Reward Token";
    string public constant REWARD_SYMBOL = "RWDT";

    function setUp() public {
        rewardToken = new Mock20(REWARD_NAME, REWARD_SYMBOL);
        mini = Mini(
            HuffDeployer
                .config()
                .with_args(
                    bytes.concat(
                        abi.encode(address(rewardToken)),
                        abi.encode(address(rewardToken))
                    )
                )
                .deploy("Mini")
        );
    }

    function testConstructorArgs() public {
        address rewardsToken = mini.REWARDS_TOKEN();
        address stakingToken = mini.STAKING_TOKEN();
        assertEq(rewardsToken, address(rewardToken));
        assertEq(stakingToken, address(rewardToken));
    }
}
