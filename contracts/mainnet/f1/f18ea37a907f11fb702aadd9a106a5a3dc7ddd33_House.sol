/**
 *Submitted for verification at polygonscan.com on 2023-02-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract House {

    using SafeMath for uint256;

    struct tokenAmount {
        address tokenAddress;
        uint256 value;
    }
    struct userWallet {
        address walletAddress;
        bool canWithdraw;
        tokenAmount[] amount;
    }
    struct treasuryAmount {
        address tokenAddress;
        uint256 value;
    }
    struct treasuryWalletStruct {
        address walletAddress;
        treasuryAmount[] amount;
    }


    // the address of the owner of the contract
    address public owner;
    // boolean flag to indicate if the contract is paused or not
    bool public paused;
    // array of allowed token addresses
    address[] public allowedTokens;
    // the number of wallets
    uint256 public numberOfWallets;
    // the variable for the treasuryWallet
    treasuryWalletStruct private treasuryWallet;
    // ReentrancyGuard
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    mapping(uint256 => userWallet) public wallet;

    // event to log deposit transactions
    event DepositEvent(address indexed walletAddress, address indexed tokenAddress, uint256 depositAmount);
    // event to log withdraw transactions
    event WithdrawEvent(address indexed walletAddress, uint256 withdrawAmount);
    // event to log withdrawToken transactions
    event WithdrawTokenEvent(address indexed walletAddress, address indexed tokenAddress, uint256 withdrawAmount);
    // event to log depositTreasury transactions
    event DepositTreasuryEvent(address indexed tokenAddress, uint256 depositAmount);
    // event to log withdrawTreasury transactions
    event WithdrawTreasuryEvent(address indexed tokenAddress, uint256 withdrawAmount);
    // event to log approve transactions
    //event TokenApprovedEvent(address tokenAddress, uint256 amount);
    // event to log cleanContract transactions
    //event ContractCleanedEvent(address tokenAddress, address to, uint256 amount);
    // event to log updateBalance transactions
    event UpdateBalanceEvent(address indexed walletAddress, address indexed tokenAddress, uint256 changeAmount, bool decreaseUserBalance);
    // event to log addToken transactions
    event TokenAddedEvent(address indexed tokenAddress, string tokenName, string tokenSymbol, uint256 tokenDecimals);
    // event to log removeToken transactions
    event TokenRemovedEvent(address indexed tokenAddress);
    // event to log pause transactions
    event ContractPausedEvent();
    // event to log resume transactions
    event ContractResumedEvent();
    // event to log the changeTreasury transaction
    event ChangeTreasuryEvent(address indexed _oldTreasury, address indexed _newTreasury);
    // event to log transferOwnership transactions
    event OwnershipTransferredEvent(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        numberOfWallets = 0;
        treasuryWallet.walletAddress = 0xeB367A6aAE014fC8A9c4e692a736a07F1cbB45A6; // Can never be the owner!
        _status = _NOT_ENTERED;
    }

    // Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // Prevents a contract from calling itself, directly or indirectly.
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
        _;
        // By storing the original value once again, a refund is triggered (https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * View function to return the address of the Treasury wallet
     * @return The address of the Treasury wallet
     */
    function getTreasuryWalletAddress() public view returns (address) {
        return treasuryWallet.walletAddress;
    }

    /**
    * getTreasuryBalances function retrieves the token addresses and balances associated with the Treasury wallet.
    * @return tokenAddresses An array of token addresses held in the Treasury wallet
    * @return tokenBalances An array of token balances held in the Treasury wallet
    */
    function getTreasuryBalances() public view returns (address[] memory tokenAddresses, uint256[] memory tokenBalances) {
        // Initialize two dynamic arrays to store the token addresses and balances of the Treasury wallet
        address[] memory addresses = new address[](treasuryWallet.amount.length);
        uint256[] memory balances = new uint256[](treasuryWallet.amount.length);
        // Loop through the amount array of the Treasury wallet to retrieve the token addresses and balances
        for (uint256 i = 0; i < treasuryWallet.amount.length; i++) {
            // Store the token address at the current index in the addresses array
            addresses[i] = treasuryWallet.amount[i].tokenAddress;
            // Store the token balance at the current index in the balances array
            balances[i] = treasuryWallet.amount[i].value;
        }
        // Return the populated arrays of token addresses and balances
        return (addresses, balances);
    }

    /**
    * getUserBalances function retrieves the token addresses and balances associated with a user's wallet.
    * @param _walletAddress The address of the wallet to retrieve information from
    * @return tokenAddresses An array of token addresses held in the wallet
    * @return tokenBalances An array of token balances held in the wallet
    */
    function getUserBalances(address _walletAddress) public view returns (address[] memory tokenAddresses, uint256[] memory tokenBalances) {
        // Initialize a variable to store the index of the wallet address in the wallet array.
        uint256 walletIndex;
        // Loop through all the wallets of the contract
        for (uint256 i = 0; i < numberOfWallets; i++) {
            // Check if the current wallet address is equal to the given walletAddress
            if (wallet[i].walletAddress == _walletAddress) {
                // If it is, store the index and break out of the loop.
                walletIndex = i;
                break;
            }
        }
        // Get the number of tokens in the wallet
        uint256 tokenCount = wallet[walletIndex].amount.length;
        // Initialize two arrays to store the token addresses and their respective balances
        tokenAddresses = new address[](tokenCount);
        tokenBalances = new uint256[](tokenCount);
        // Loop through the tokens of the wallet
        for (uint256 i = 0; i < tokenCount; i++) {
            // Store the token address at the current index in the addresses array
            tokenAddresses[i] = wallet[walletIndex].amount[i].tokenAddress;
            // Store the token balance at the current index in the balances array
            tokenBalances[i] = wallet[walletIndex].amount[i].value;
        }
    // Return the populated arrays of token addresses and balances
    return (tokenAddresses, tokenBalances);
    }

    /**
     * View function to return the list of addresses of the allowed tokens
     * @return The list of addresses on the allowed token list
     */
    function getAllowedTokens() public view returns (address[] memory) {
        return allowedTokens;
    }

    /**
     * View function to return if an address in on the allowed token list
     * @return True or flase wether an address is on the allowed token list
     */
    function isTokenAdded(address _tokenAddress) public view returns (bool) {
        // loop through the allowedTokens list
        for(uint256 i = 0; i < allowedTokens.length; i++) {
            // check if the token being added already exists in the list
            if(_tokenAddress == allowedTokens[i]) {
                // if the token is on the list, return true
                return true;
            }
        }
        // if the token is not on the list, return false
        return false;
    }

    /**
     * Function that allows a user to deposit a specified amount of a specific token to their wallet balance.
     * @param _tokenAddress The address of the token being deposited.
     * @param _depositAmount The amount of the token being deposited.
    */
    function depositToken(address _tokenAddress, uint256 _depositAmount) external nonReentrant {
        // require that the contract is not paused
        require(!paused, "The contract is paused");
        // require that the walletAddress is not the owner address
        require(msg.sender != owner, "Owner cannot deposit");
        // require that the walletAddress is not the Treasury address
        require(msg.sender != treasuryWallet.walletAddress, "Treasury cannot deposit");
        // require that the tokenAddress is a valid crypto address
        require(_tokenAddress != address(0), "Invalid token address");
        // require that the depositAmount is positive
        require(_depositAmount > 0, "Invalid deposit amount");
        // require that the token is on the allowed tokens list
        require(isTokenAdded(_tokenAddress) == true, "Token is not on the allowedTokens list");
        IERC20 _token = IERC20(_tokenAddress);
        // require that the contract has enough allowance from the walletAddress
        require(_token.allowance(msg.sender, address(this)) >= _depositAmount, "Allowance Error: walletAddress does not have enough allowance from the token contract");
        // transfer the depositAmount of the token from the walletAddress to the Treasury wallet
        require(_token.transferFrom(msg.sender, treasuryWallet.walletAddress, _depositAmount), "TransferFrom Error");
        // emit the Deposit event to log the transaction
        emit DepositEvent(msg.sender, _tokenAddress, _depositAmount);
        bool walletExists = false;
        // loop through the wallets
        for(uint256 _cnt1 = 0; _cnt1 < numberOfWallets; _cnt1++) {
            // if the wallet is the same as the walletAddress
            if(wallet[_cnt1].walletAddress == msg.sender) {
                bool tokenExists = false;
                // loop through the tokens of the wallet
                for(uint256 _cnt2 = 0; _cnt2 < wallet[_cnt1].amount.length; _cnt2++) {
                    // if the token is the same as the tokenAddress
                    if(wallet[_cnt1].amount[_cnt2].tokenAddress == _tokenAddress) {
                        // add the depositAmount to the token balance of the wallet
                        wallet[_cnt1].amount[_cnt2].value = wallet[_cnt1].amount[_cnt2].value.add(_depositAmount);
                        walletExists = true;
                        tokenExists = true;
                    }
                }
                // if the token does not exist
                if(tokenExists == false) {
                    // add the token to the tokens of the wallet
                    tokenAmount memory perToken = tokenAmount(_tokenAddress, _depositAmount);
                    wallet[_cnt1].amount.push(perToken);
                    walletExists = true;
                }
            }
        }
        // if the wallet does not exist
        if(walletExists == false) {
            // add the wallet to the list of wallet addresses
            wallet[numberOfWallets].walletAddress = msg.sender;
            wallet[numberOfWallets].canWithdraw = false;
            // add the depositAmount of the tokenAddress to the wallet
            tokenAmount memory perToken = tokenAmount(_tokenAddress, _depositAmount);
            wallet[numberOfWallets].amount.push(perToken);
            numberOfWallets = numberOfWallets.add(1);
        }
    }

    /**
     * Function that allows a user to withdraw a specified amount of a specific token from their wallet balance.
     * @param _tokenAddress The address of the token being withdrawn.
     * @param _withdrawAmount The amount of the token being withdrawn.
    */
    function withdraw(address _tokenAddress, uint256 _withdrawAmount) external nonReentrant {
        // require that the contract is not paused
        require(!paused, "The contract is paused");
        // require that the walletAddress is not the owner address
        require(msg.sender != owner, "Owner cannot withdraw");
        // require that the walletAddress is not the Treasury address
        require(msg.sender != treasuryWallet.walletAddress, "Treasury cannot withdraw");
        // require that the tokenAddress is a valid crypto address
        require(_tokenAddress != address(0), "Invalid token address");
        // require that the withdrawAmount is positive
        require(_withdrawAmount > 0, "Invalid withdraw amount");
        // require that the token is on the allowed tokens list
        require(isTokenAdded(_tokenAddress) == true, "Token is not on the allowedTokens list");
        // loop through the list of wallets
        for(uint256 _cnt1 = 0; _cnt1 < numberOfWallets; _cnt1++) {
            // if the wallet is the same as the walletAddress
            if(wallet[_cnt1].walletAddress == msg.sender) {
                // require that the walletAddress has not asked for withdrawal yet
                require(wallet[_cnt1].canWithdraw == false, "Cannot request multiple withdrawals at the same time");
                // allow the walletAddress to withdraw
                wallet[_cnt1].canWithdraw = true;
                // emit the Withdraw event to log the transaction
                emit WithdrawEvent(msg.sender, _withdrawAmount);
            }
        }
    }

    /**
      Function that allows the contract owner to withdraw a specified amount of a specific token to their wallet.
     * @param _walletAddress The address of the user withdrawing the tokens.
     * @param _tokenAddress The address of the token being withdrawn.
     * @param _withdrawAmount The amount of the token being withdrawn.
    */
    function withdrawTokens(address _walletAddress, address _tokenAddress, uint256 _withdrawAmount) external onlyOwner nonReentrant {
        // require that the contract is not paused
        require(!paused, "The contract is paused");
        // require that the walletAddress is a valid crypto address
        require(_walletAddress != address(0), "Invalid wallet address");
        // require that the walletAddress is not the owner address
        require(_walletAddress != owner, "Owner cannot withdraw");
        // require that the walletAddress is not the Treasury address
        require(_walletAddress != treasuryWallet.walletAddress, "Treasury cannot withdraw");
        // require that the tokenAddress is a valid crypto address
        require(_tokenAddress != address(0), "Invalid token address");
        // require that the withdrawAmount is positive
        require(_withdrawAmount > 0, "Invalid withdraw amount");
        // require that the token is on the allowed tokens list
        require(isTokenAdded(_tokenAddress) == true, "Token is not on the allowedTokens list");
        IERC20 _token = IERC20(_tokenAddress);
        // require that the contract has enough allowance from the wallet
        require(_token.allowance(msg.sender, address(this)) >= _withdrawAmount, "Allowance Error: msg.sender does not have enough allowance from the token contract"); // Check Treasury allowance?
        // loop through the list of wallets
        for(uint256 _cnt1 = 0; _cnt1 < numberOfWallets; _cnt1++) {
            // if the wallet is the same as the walletAddress
            if(wallet[_cnt1].walletAddress == _walletAddress) {
                // loop through the tokens of the wallet
                for(uint256 _cnt2 = 0; _cnt2 < wallet[_cnt1].amount.length; _cnt2++) {
                    // if the token is the same as the tokenAddress
                    if(wallet[_cnt1].amount[_cnt2].tokenAddress == _tokenAddress) {
                        // require that the wallet has requested a withdrawal
                        require(wallet[_cnt1].canWithdraw == true, "walletAddress must call withdraw() function first");
                        // require that the wallet has enough balance of that token
                        require(_withdrawAmount <= wallet[_cnt1].amount[_cnt2].value, "You cannot withdraw this amount");
                        // transfer the withdrawAmount of the token to the walletAddress from the Treasury
                        require(_token.transferFrom(treasuryWallet.walletAddress, _walletAddress, _withdrawAmount), "TransferFrom Error");
                        // emit the WithdrawToken event to log the transaction
                        emit WithdrawTokenEvent(_walletAddress, _tokenAddress, _withdrawAmount);
                        // update the balance of the tokenAddress of the walletAddress
                        wallet[_cnt1].amount[_cnt2].value = wallet[_cnt1].amount[_cnt2].value.sub(_withdrawAmount);
                    }
                }
                // prevent the walletAddress to withdraw
                wallet[_cnt1].canWithdraw = false;
            }
        }
    }

    /**
     * Function that allows the contract owner to deposit a specified amount of a specific token to the Treasury balance.
     * @param _tokenAddress The address of the token being deposited.
     * @param _depositAmount The amount of the token being deposited.
    */
    function depositTreasury(address _tokenAddress, uint256 _depositAmount) external onlyOwner nonReentrant {
        // require that the tokenAddress is a valid crypto address
        require(_tokenAddress != address(0), "Invalid token address");
        // require that the depositAmount is positive
        require(_depositAmount > 0, "Invalid deposit amount");
        // require that the token is on the allowed tokens list
        require(isTokenAdded(_tokenAddress) == true, "Token is not on the allowedTokens list");
        IERC20 _token = IERC20(_tokenAddress);
        // require that the contract has enough allowance from the owner
        require(_token.allowance(owner, address(this)) >= _depositAmount, "Allowance Error: walletAddress does not have enough allowance from the token contract"); // Check Treasury allowance?
        // require that the transfer goes through successfully
        require(_token.transferFrom(owner, treasuryWallet.walletAddress, _depositAmount), "TransferFrom Error");
        // emit the DepositTreasury event to log the transaction
        emit DepositTreasuryEvent(_tokenAddress, _depositAmount);
        bool tokenExists = false;
        // loop through the list of tokens of the Treasury
        for(uint256 cnt = 0; cnt < treasuryWallet.amount.length; cnt++) {
            // if the token is the same as the tokenAddress
            if(treasuryWallet.amount[cnt].tokenAddress == _tokenAddress) {
                tokenExists = true;
                treasuryWallet.amount[cnt].value = treasuryWallet.amount[cnt].value.add(_depositAmount);
            }
        }
        // if the token does not exist
        if(tokenExists == false) {
            treasuryAmount memory perTreasury = treasuryAmount(_tokenAddress, _depositAmount);
            // add the new token with the depositAmount as value to the Treasury
            treasuryWallet.amount.push(perTreasury);
        }
    }

    /**
     * Function that allows the contract owner to withdraw a specified amount of a specific token from the Treasury balance.
     * @param _tokenAddress The address of the token being withdrawn.
     * @param _withdrawAmount The amount of the token being withdrawn.
    */
    function withdrawTreasury(address _tokenAddress, uint256 _withdrawAmount) external onlyOwner nonReentrant {
        // require that the tokenAddress is a valid crypto address
        require(_tokenAddress != address(0), "Invalid token address");
        // require that the withdrawAmount is positive
        require(_withdrawAmount > 0, "Invalid withdraw amount");
        // require that the token is on the allowed tokens list
        require(isTokenAdded(_tokenAddress) == true, "Token is not on the allowedTokens list");
        IERC20 _token = IERC20(_tokenAddress);
        // loop through the list of tokens of the Treasury
        for(uint256 cnt = 0; cnt < treasuryWallet.amount.length; cnt++) {
            // if the token is the same as the tokenAddress
            if(treasuryWallet.amount[cnt].tokenAddress == _tokenAddress) {
                uint256 _balance = _token.balanceOf(treasuryWallet.walletAddress);
                // require that the Treasury has enough balance to withdraw
                require(_withdrawAmount <= _balance, "Contract has not enough tokens");
                // require that the Treasury has enough balance to withdraw
                require(_withdrawAmount <= treasuryWallet.amount[cnt].value, "You cannot withdraw this amount");
                // require that the contract has enough allowance from the Treasury
                require(_token.allowance(treasuryWallet.walletAddress, address(this)) >= _withdrawAmount, "Allowance Error: walletAddress does not have enough allowance from the token contract");
                // require that the tokens transfer successfully
                require(_token.transferFrom(treasuryWallet.walletAddress, owner, _withdrawAmount), "TransferFrom Error");
                // emit the WithdrawTreasury event to log the transaction
                emit WithdrawTreasuryEvent(_tokenAddress, _withdrawAmount);
                // update the balance of the token of the Treasury
                treasuryWallet.amount[cnt].value = treasuryWallet.amount[cnt].value.sub(_withdrawAmount);
            }
        }
    }

    /**
     * Function that allows the contract owner to update the balance of a wallet and Treasury
     * @param _walletAddress The address of the user getting the balance update.
     * @param _tokenAddress The address of the token being updated.
     * @param _updateAmount The amount of the token being updated.
     * @param _decreaseUserBalance The flag determining whether the balance of the user is decreasing or increasing.
    */
    function updateBalance(address _walletAddress, address _tokenAddress, uint256 _updateAmount, bool _decreaseUserBalance) external onlyOwner nonReentrant {
        // require that the contract is not paused
        require(!paused, "The contract is paused");
        // require that the walletAddress is a valid crypto address
        require(_walletAddress != address(0), "Invalid wallet address");
        // require that the walletAddress is not the owner address
        require(_walletAddress != owner, "Owner cannot be updated");
        // require that the walletAddress is not the Treasury address
        require(_walletAddress != treasuryWallet.walletAddress, "Treasury cannot be updated");
        // require that the tokenAddress is a valid crypto address
        require(_tokenAddress != address(0), "Invalid token address");
        // require that the withdrawAmount is positive
        require(_updateAmount > 0, "Invalid withdraw amount");
        // require that the token is on the allowed tokens list
        require(isTokenAdded(_tokenAddress) == true, "Token is not on the allowedTokens list");
        // declare the tokenDeposited variable to check if the user has a balance of the token
        bool tokenDeposited = false;
        // loop through the list of wallets
        for(uint256 _cnt1 = 0; _cnt1 < numberOfWallets; _cnt1++) {
            // if the wallet is the same as the walletAddress
            if(wallet[_cnt1].walletAddress == _walletAddress) {
                // loop through the list of tokens of the user
                for(uint256 _cnt2 = 0; _cnt2 < wallet[_cnt1].amount.length; _cnt2++) {
                    // if the token is the same as the tokenAddress
                    if(wallet[_cnt1].amount[_cnt2].tokenAddress == _tokenAddress) {
                        // if the decreaseUserBalance is true
                        if(_decreaseUserBalance == true) {
                            // decrease the user's balance with the updateAmount
                            wallet[_cnt1].amount[_cnt2].value = wallet[_cnt1].amount[_cnt2].value.sub(_updateAmount);
                        // if the decreaseUserBalance is false
                        } else {
                            // increase the user's balance with the updateAmount
                            wallet[_cnt1].amount[_cnt2].value = wallet[_cnt1].amount[_cnt2].value.add(_updateAmount);
                        }
                        tokenDeposited = true;
                    }
                }
            }
        }
        // require that the user has balance of the token
        require(tokenDeposited == true, "Token not found in user's wallet");
        // declare the tokenExists variable to check if the Treasury has a balance of the token
        bool tokenExists = false;
        // loop through the list of tokens of the Treasury
        for(uint256 cnt = 0; cnt < treasuryWallet.amount.length; cnt++) {
            // if the token is the same as the tokenAddress
            if(treasuryWallet.amount[cnt].tokenAddress == _tokenAddress) {
                // if the decreaseUserBalance is false
                if(_decreaseUserBalance == false) {
                    // decrease the Treasury's balance with the updateAmount
                    treasuryWallet.amount[cnt].value = treasuryWallet.amount[cnt].value.sub(_updateAmount);
                // if the decreaseUserBalance is true
                } else {
                    // increase the Treasury's balance with the updateAmount
                    treasuryWallet.amount[cnt].value = treasuryWallet.amount[cnt].value.add(_updateAmount);
                }
                tokenExists = true;
            }
        }
        // if the token does not exists
        if(tokenExists == false) {
            treasuryAmount memory perTreasury = treasuryAmount(_tokenAddress, _updateAmount);
            // add the new token with the updateBalance as value to the Treasury
            treasuryWallet.amount.push(perTreasury);
        }
        // emit the UpdateBalance event to log the transaction
        emit UpdateBalanceEvent(_walletAddress, _tokenAddress, _updateAmount, _decreaseUserBalance);
    }

    function approveToken(address _tokenAddress) public onlyOwner {
        // require that the tokenAddress is a valid crypto address
        require(_tokenAddress != address(0), "Invalid token address");
        IERC20 _token = IERC20(_tokenAddress);
        uint256 _amount = _token.balanceOf(address(this));
        // approve the token for the smart contract
        require(_token.approve(address(this), _amount), "Approval Error");
        // Emit the TokenApproved event to log the transaction
        //emit TokenApprovedEvent(_tokenAddress, _amount);
    }

    function cleanContract(address _tokenAddress, uint256 _amount) external onlyOwner {
        // require that the tokenAddress is a valid crypto address
        require(_tokenAddress != address(0), "Invalid token address");
        // require that the withdrawAmount is positive
        require(_amount > 0, "Invalid withdraw amount");
        IERC20 _token = IERC20(_tokenAddress);
        uint256 _balance = _token.balanceOf(address(this));
        // require that the contract has enough balance to remove
        require(_amount <= _balance, "Contract has not enough tokens");
        // Transfer the specified amount of tokens from the contract to the owner
        require(_token.transfer(owner, _amount), "Transfer Error");
        // Emit the ContractCleaned event to log the transaction
        //emit ContractCleanedEvent(_tokenAddress, owner, _amount);
    }

    /**
      Function that allows the contract owner to add a new token to the allowedTokens
     * @param _tokenAddress The address of the token being added
    */
    function addToken(address _tokenAddress) external onlyOwner {
        // require that the tokenAddress is a valid crypto address
        //require(_tokenAddress != address(0), "Invalid token address");
        // check if there is any token in the list
        if(allowedTokens.length > 0) {
            // loop through the list of tokens
            require(isTokenAdded(_tokenAddress) == false, "Token is already on the allowedTokens list");
        }
        // if the token does not exist in the list, add it to the list
        allowedTokens.push(_tokenAddress);
        // get the token details
        IERC20 _token = IERC20(_tokenAddress);
        // emit the TokenAdded event to log the transaction
        emit TokenAddedEvent(_tokenAddress, _token.name(), _token.symbol(), _token.decimals());
    }

    /**
      Function that allows the contract owner to remove a token from the allowedTokens
     * @param _tokenIndex The index of the token being removed
    */
    function removeToken(uint256 _tokenIndex) external onlyOwner {
        // require the index to be valid
        require(_tokenIndex < allowedTokens.length, "tokenIndex out of range");
        // declare a variable for the address of the token being removed
        address _tokenAddress = allowedTokens[_tokenIndex];
        // loop through the tokens from the tokenIndex
        for (uint i = _tokenIndex; i < allowedTokens.length - 1; i++){
            // move each token down by one
            allowedTokens[i] = allowedTokens[i + 1];
        }
        // remove the last element
        allowedTokens.pop();
        // emit the TokenRemoved event to log the transaction
        emit TokenRemovedEvent(_tokenAddress);
    }

    /**
      Function that allows the contract owner to pause the contract
      This prevents any further transactions to be made until the contract is resumed
    */
    function pause() external onlyOwner {
        // require that the contract is not paused
        //require(!paused, "The contract is paused");
        // pauses the contract by setting the paused variable to true
        paused = true;
        // emit the ContractPaused event to log the transaction
        emit ContractPausedEvent();
    }

    /**
      Function that allows the contract owner to resume the contract
      This allows transactions to be made after the contract was previously paused
    */
    function resume() external onlyOwner {
        // require that the contract is paused
        //require(paused, "The contract is not paused");
        //resumes the contract by setting the paused variable to false
        paused = false;
        // emit the ContractResumed event to log the transaction
        emit ContractResumedEvent();
    }

    /**
      Function that allows the contract owner to change the Treasury address
     * @param _newTreasury The address of the new Treasury.
    */
    function changeTreasury(address _newTreasury) external onlyOwner {
        // require that the newTreasury is a valid crypto address
        require(_newTreasury != address(0), "Invalid wallet address");
        // require that the newTreasury is not the current Treasury
        //require(_newTreasury != treasuryWallet.walletAddress, "New Treasury cannot be the current Treasury");
        // require that the newTreasury is not the Treasury
        require(_newTreasury != owner, "Treasury cannot be the owner");
        // emit the ChangeTreasury event to log the transaction
        emit ChangeTreasuryEvent(treasuryWallet.walletAddress, _newTreasury);
        // set newOwner as owner
        treasuryWallet.walletAddress = _newTreasury;
    }

    /**
      Function that allows the contract owner to transfer the ownership of the contract
     * @param _newOwner The address of the new owner of the contract.
    */
    function transferOwnership(address _newOwner) external onlyOwner {
        // require that the newOwner is a valid crypto address
        require(_newOwner != address(0), "Invalid wallet address");
        // require that the newOwner is not the owner
        require(_newOwner != owner, "You are the owner");
        // require that the newOwner is not the current Treasury
        require(_newOwner != treasuryWallet.walletAddress, "newOwner cannot be the current Treasury");
        // emit the OwnershipTransferred event to log the transaction
        emit OwnershipTransferredEvent(owner, _newOwner);
        // set newOwner as owner
        owner = _newOwner;
    }
}