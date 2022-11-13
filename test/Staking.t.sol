// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "solidity/Mock20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface Staking {
    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function stake(uint256) external;

    function withdraw(uint256) external;

    function getReward() external;

    function exit() external;

    function notifyRewardAmount(uint256) external;

    function recoverERC20(address, uint256) external;

    function setRewardsDuration(uint256) external;
}

contract StakingTest is Test {
    /// @dev Address of the Staking contract.
    Staking public staking;
    Mock20 public rewardToken;

    string constant public REWARD_NAME = "Reward Token";
    string constant public REWARD_SYMBOL = "RWDT";

    /// @dev Setup the testing environment.
    function setUp() public {
        rewardToken = new Mock20(REWARD_NAME, REWARD_SYMBOL);
        staking = Staking(
            HuffDeployer
                .config()
                .with_args(
                    bytes.concat(
                        abi.encode(address(rewardToken)),
                        abi.encode(address(rewardToken))
                    )
                )
                .deploy("Staking")
        );
        uint256 myBalance = rewardToken.balanceOf(address(this));
        assertEq(myBalance, 1000000e18);
        rewardToken.transfer(address(staking), 100000e18);
        uint256 stakingBalance = rewardToken.balanceOf(address(staking));
        assertEq(stakingBalance, 100000e18);
    }

    function testMockERC20Metadata() public {
        string memory tokenName = rewardToken.name();
        string memory tokenSymbol = rewardToken.symbol();
        assertEq(keccak256(abi.encode(tokenName)), keccak256(abi.encode(REWARD_NAME)));
        assertEq(keccak256(abi.encode(tokenSymbol)), keccak256(abi.encode(REWARD_SYMBOL)));
    }

    function testBalanceOf() public {
        uint256 balance = staking.balanceOf(address(this));
        assertEq(balance,0);
    }

    function testTotalSupply() public {
        uint256 totalSupply = staking.totalSupply();
        assertEq(totalSupply, 0);
    }

    // function testRecoverERC20() public {
    //     staking.recoverERC20(address(rewardToken), 100000e18);
    //     uint256 myBalance = rewardToken.balanceOf(address(this));
    //     assertEq(myBalance, 1000000e18);
    // }

    // function testRewardForDuration() public {
    //     uint256 rewardDuration = 2592000;
    //     uint256 rewardAmount = 100000e18;
    //     staking.setRewardsDuration(rewardDuration); // month
    //     staking.notifyRewardAmount(rewardAmount);
    //     uint256 rewardForDuration = staking.getRewardForDuration();
    //     uint256 expectation = rewardAmount / rewardDuration;
    //     assertEq(rewardForDuration, expectation);
    // }
}
