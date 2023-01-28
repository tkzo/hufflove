// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "solidity/Staking/Mock20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "solidity/Staking/Stakable.sol";

interface Staking {
    function pendingOwner() external view returns (address);

    function owner() external view returns (address);

    function rewardsDuration() external view returns (uint256);

    function rewardsToken() external view returns (address);

    function stakingToken() external view returns (address);

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
    using SafeMath for uint256;
    /// @dev Address of the Staking contract.
    Staking public staking;
    Stakable public stakable;
    Mock20 public rewardToken;
    Mock20 public randomToken;

    string public constant REWARD_NAME = "Reward Token";
    string public constant REWARD_SYMBOL = "RWDT";
    string public constant RANDOM_NAME = "Random Token";
    string public constant RANDOM_SYMBOL = "RNDT";

    uint256 public constant STAKE_AMOUNT = 50000e18;
    uint256 public constant REWARD_AMOUNT = 100000e18;
    uint256 public constant MINTED_AMOUNT = 1000000e18;
    uint256 public constant REWARD_DURATION = 2592000;
    uint256 public constant MAX_UINT256 = type(uint256).max;

    /// @dev Setup the testing environment.
    function setUp() public {
        rewardToken = new Mock20(REWARD_NAME, REWARD_SYMBOL);
        randomToken = new Mock20(RANDOM_NAME, RANDOM_SYMBOL);

        staking = Staking(
            HuffDeployer
                .config()
                .with_args(
                    bytes.concat(
                        abi.encode(address(rewardToken)),
                        abi.encode(address(rewardToken)),
                        abi.encode(address(this))
                    )
                )
                .deploy("Staking")
        );
        rewardToken.transfer(address(staking), REWARD_AMOUNT);
        randomToken.transfer(address(staking), REWARD_AMOUNT);

        // deploy solidity version
        stakable = new Stakable(address(rewardToken), address(rewardToken));
        rewardToken.transfer(address(stakable), REWARD_AMOUNT);
    }

    function testMockERC20Metadata() public {
        string memory tokenName = rewardToken.name();
        string memory tokenSymbol = rewardToken.symbol();
        assertEq(
            keccak256(abi.encode(tokenName)),
            keccak256(abi.encode(REWARD_NAME))
        );
        assertEq(
            keccak256(abi.encode(tokenSymbol)),
            keccak256(abi.encode(REWARD_SYMBOL))
        );
    }

    function testMockERC20Approve() public {
        rewardToken.approve(address(staking), MAX_UINT256);
        uint256 allowance = rewardToken.allowance(
            address(this),
            address(staking)
        );
        assertEq(allowance, MAX_UINT256);
    }

    function testConstructorArgs() public {
        address rewardsToken = staking.rewardsToken();
        address stakingToken = staking.stakingToken();
        assertEq(rewardsToken, address(rewardToken));
        assertEq(stakingToken, address(rewardToken));
    }

    function testOwner() public {
        address owner = staking.owner();
        assertEq(owner, address(this));
    }

    function testLastTimeRewardApplicable() public {
        uint256 result = staking.lastTimeRewardApplicable();
        assertEq(result, 0);
    }

    function testBalanceOf() public {
        uint256 balance = staking.balanceOf(address(this));
        assertEq(balance, 0);
    }

    function testRecoverERC20() public {
        uint256 balance_pre = randomToken.balanceOf(address(this));
        uint256 diff = MINTED_AMOUNT.sub(REWARD_AMOUNT);
        assertEq(balance_pre, diff);

        staking.recoverERC20(address(randomToken), REWARD_AMOUNT);
        uint256 myBalance = randomToken.balanceOf(address(this));
        assertEq(myBalance, MINTED_AMOUNT);
    }

    function testRewardsDuration() public {
        uint256 duration_pre = staking.rewardsDuration();
        assertEq(duration_pre, 0);
    }

    function testSetRewardsDuration() public {
        staking.setRewardsDuration(REWARD_DURATION);
        uint256 duration_after = staking.rewardsDuration();
        assertEq(duration_after, REWARD_DURATION);
    }

    function testRewardPerToken() public {
        uint256 rpt = staking.rewardPerToken();
        uint256 totalSupply = staking.totalSupply();
        if (totalSupply == 0) {
            assertEq(rpt, 0);
        }
    }

    function testGetRewardForDuration() public {
        staking.setRewardsDuration(REWARD_DURATION);
        staking.notifyRewardAmount(REWARD_AMOUNT);
        uint256 rewardForDuration = staking.getRewardForDuration();
        assertApproxEqRel(rewardForDuration, REWARD_AMOUNT, 1e17);
    }

    function testStake() public {
        staking.setRewardsDuration(REWARD_DURATION);
        staking.notifyRewardAmount(REWARD_AMOUNT);
        rewardToken.approve(address(staking), MAX_UINT256);
        staking.stake(STAKE_AMOUNT);
        uint256 total_supply = staking.totalSupply();
        assertEq(total_supply, STAKE_AMOUNT);
        uint256 staked = staking.balanceOf(address(this));
        assertEq(staked, STAKE_AMOUNT);
        uint256 rewardPerToken = staking.rewardPerToken();
        console.log("Reward Per Token LOG:", rewardPerToken);
    }

    function testEarned() public {
        staking.setRewardsDuration(REWARD_DURATION);
        staking.notifyRewardAmount(REWARD_AMOUNT);
        rewardToken.approve(address(staking), MAX_UINT256);
        uint256 earned_pre = staking.earned(address(this));
        assertEq(earned_pre, 0);
        staking.stake(STAKE_AMOUNT);
        vm.warp(block.timestamp + REWARD_DURATION);
        uint256 earned_post = staking.earned(address(this));
        assertApproxEqRel(earned_post, REWARD_AMOUNT, 1e17);
    }

    function testGetReward() public {
        staking.setRewardsDuration(REWARD_DURATION);
        staking.notifyRewardAmount(REWARD_AMOUNT);
        rewardToken.approve(address(staking), MAX_UINT256);
        staking.stake(STAKE_AMOUNT);
        uint256 balance_pre = rewardToken.balanceOf(address(this));
        vm.warp(block.timestamp + REWARD_DURATION);
        staking.getReward();
        uint256 balance_post = rewardToken.balanceOf(address(this));
        uint256 diff = balance_post - balance_pre;
        assertApproxEqRel(diff, REWARD_AMOUNT, 1e17);
    }

    function testWithdraw() public {
        staking.setRewardsDuration(REWARD_DURATION);
        staking.notifyRewardAmount(REWARD_AMOUNT);
        rewardToken.approve(address(staking), MAX_UINT256);
        uint256 balance_pre = rewardToken.balanceOf(address(this));
        staking.stake(STAKE_AMOUNT);
        vm.warp(block.timestamp + REWARD_DURATION);
        staking.withdraw(STAKE_AMOUNT);
        uint256 balance_post = rewardToken.balanceOf(address(this));
        assertEq(balance_pre, balance_post);
    }

    // tests for rough gas comparison
    function test_Solidity() public {
        stakable.setRewardsDuration(REWARD_DURATION);
        stakable.notifyRewardAmount(REWARD_AMOUNT);
        rewardToken.approve(address(stakable), MAX_UINT256);
        stakable.stake(STAKE_AMOUNT);
        vm.warp(block.timestamp + REWARD_DURATION);
        stakable.getReward();
        stakable.unstake(STAKE_AMOUNT);
    }

    function test_Huff() public {
        staking.setRewardsDuration(REWARD_DURATION);
        staking.notifyRewardAmount(REWARD_AMOUNT);
        rewardToken.approve(address(staking), MAX_UINT256);
        staking.stake(STAKE_AMOUNT);
        vm.warp(block.timestamp + REWARD_DURATION);
        staking.getReward();
        staking.withdraw(STAKE_AMOUNT);
    }
}
