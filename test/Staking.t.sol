// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "solidity/Mock20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

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
    Mock20 public rewardToken;
    Mock20 public randomToken;

    string public constant REWARD_NAME = "Reward Token";
    string public constant REWARD_SYMBOL = "RWDT";
    uint256 public constant REWARD_AMOUNT = 100000e18;
    uint256 public constant MINTED_AMOUNT = 1000000e18;

    string public constant RANDOM_NAME = "Random Token";
    string public constant RANDOM_SYMBOL = "RNDT";

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

    function testConstructorArgs() public {
        address rewardsToken = staking.rewardsToken();
        address stakingToken = staking.stakingToken();
        assertEq(rewardsToken, address(rewardToken));
        assertEq(stakingToken, address(rewardToken));
    }

    function testLastTimeRewardApplicable() public {
        uint256 result = staking.lastTimeRewardApplicable();
        assertEq(result, block.timestamp);
    }

    function testBalanceOf() public {
        uint256 balance = staking.balanceOf(address(this));
        assertEq(balance, 0);
    }

    function testTotalSupply() public {
        uint256 totalSupply = staking.totalSupply();
        assertEq(totalSupply, 0);
    }

    function testRewardsDuration() public {
        uint256 duration = staking.rewardsDuration();
        assertEq(duration, 0);
    }

    function testOwner() public {
        address owner = staking.owner();
        assertEq(owner, address(this));
    }

    function testRecoverERC20() public {
        uint256 balance_pre = randomToken.balanceOf(address(this));
        uint256 diff = MINTED_AMOUNT.sub(REWARD_AMOUNT);
        assertEq(balance_pre, diff);

        staking.recoverERC20(address(randomToken), REWARD_AMOUNT);
        uint256 myBalance = randomToken.balanceOf(address(this));
        assertEq(myBalance, MINTED_AMOUNT);
    }

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
