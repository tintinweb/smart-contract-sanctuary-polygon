/**
 *Submitted for verification at polygonscan.com on 2023-01-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

interface IERC20 {
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
    // the address of the treasury
    address public treasury;
    // boolean flag to indicate if the contract is paused or not
    bool public paused;
    // array of allowed token addresses
    address[] public allowedTokens;
    // the number of wallets
    uint256 public numberOfWallets;
    // the variable for the treasuryWallet
    treasuryWalletStruct private treasuryWallet;
    // ReentrencyGuard
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    mapping(uint256 => userWallet) public wallet;

    // event to log deposit transactions
    event DepositEvent(address indexed walletAddress, address indexed tokenAddress, uint256 depostAmount);
    // event to log withdraw transactions
    event WithdrawEvent(address indexed walletAddress, uint256 withdrawAmount);
    // event to log withdrawToken transactions
    event WithdrawTokenEvent(address indexed walletAddress, address indexed tokenAddress, uint256 withdrawAmount);
    // event to log Treasury deposit transactions
    event DepositTreasuryEvent(address indexed tokenAddress, uint256 depostAmount);
    // event to log Treasury withdraw transactions
    event WithdrawTreasuryEvent(address indexed tokenAddress, uint256 withdrawAmount);
    // event to log updateBalance transactions
    event UpdateBalanceEvent(address indexed walletAddress, address indexed tokenAddress, uint256 changeAmount, bool decreaseUserBalance);
    // event to log addToken transactions
    event TokenAddedEvent(address indexed tokenAddress);
    // event to log removeToken transactions
    event TokenRemovedEvent(uint256 tokenIndex);
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

    // Function that returns the allowedTokens
    function getallowedTokens() public view returns (address[] memory) {
        return allowedTokens;
    }

    // Function that returns if a token is on the allowedTokens list
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
     * @param _walletAddress The address of the user depositing the tokens.
     * @param _tokenAddress The address of the token being deposited.
     * @param _depositAmount The amount of the token being deposited.
    */
    function depositToken(address _walletAddress, address _tokenAddress, uint256 _depositAmount) external nonReentrant {
        // require that the contract is not paused
        require(!paused, "The contract is paused");
        // require that the walletAddress is the wallet making the transaction
        require(_walletAddress == msg.sender, "No access to walletAddress");
        // require that the walletAddress is a valid crypto address
        require(_walletAddress != address(0), "Invalid wallet address");
        // require that the walletAddress is not the owner address
        require(_walletAddress != owner, "Owner cannot deposit");
        // require that the walletAddress is not the Treasury address
        require(_walletAddress != treasuryWallet.walletAddress, "Treasury cannot deposit");
        // require that the tokenAddress is a valid crypto address
        require(_tokenAddress != address(0), "Invalid token address");
        // require that the depositAmount is positive
        require(_depositAmount > 0, "Invalid deposit amount");
        // require that the token is on the allowed tokens list
        require(isTokenAdded(_tokenAddress) == true, "Token is not on the allowedTokens list");
        IERC20 _token = IERC20(_tokenAddress);
        // require that the contract has enough allowance from the walletAddress
        require(_token.allowance(_walletAddress, address(this)) >= _depositAmount, "Allowance Error: walletAddress does not have enough allowance from the token contract");
        // transfer the depositAmount of the token from the walletAddress to the treasury
        require(_token.transferFrom(_walletAddress, treasuryWallet.walletAddress, _depositAmount), "TransferFrom Error");
        // emit the Deposit event to log the transaction
        emit DepositEvent(_walletAddress, _tokenAddress, _depositAmount);
        bool walletExists = false;
        // loop through the wallets
        for(uint256 _cnt1 = 0; _cnt1 < numberOfWallets; _cnt1++) {
            // if the wallet is the same as the walletAddress
            if(wallet[_cnt1].walletAddress == _walletAddress) {
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
            wallet[numberOfWallets].walletAddress = _walletAddress;   
            wallet[numberOfWallets].canWithdraw = false;
            // add the depositAmount of the tokenAddress to the wallet
            tokenAmount memory perToken = tokenAmount(_tokenAddress, _depositAmount);       
            wallet[numberOfWallets].amount.push(perToken);
            numberOfWallets = numberOfWallets.add(1);
        }
    }

    /**
     * Function that allows a user to withdraw a specified amount of a specific token from their wallet balance.
     * @param _walletAddress The address of the user withdrawing the tokens.
     * @param _tokenAddress The address of the token being withdrawn.
     * @param _withdrawAmount The amount of the token being withdrawn.
    */
    function withdraw(address _walletAddress, address _tokenAddress, uint256 _withdrawAmount) external nonReentrant {
        // require that the contract is not paused
        require(!paused, "The contract is paused");
        // require that the walletAddress is the wallet making the transaction
        require(_walletAddress == msg.sender, "No access to walletAddress");
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
        // loop through the list of wallets
        for(uint256 _cnt1 = 0; _cnt1 < numberOfWallets; _cnt1++) {
            // if the wallet is the same as the walletAddress
            if(wallet[_cnt1].walletAddress == _walletAddress) {
                // allow the walletAddress to withdraw
                wallet[_cnt1].canWithdraw = true;
                // emit the Withdraw event to log the transaction
                emit WithdrawEvent(_walletAddress, _withdrawAmount);
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
                        // prevent the walletAddress to withdraw
                        wallet[_cnt1].canWithdraw = false;
                        // update the balance of the tokenAddress of the walletAddress
                        wallet[_cnt1].amount[_cnt2].value = wallet[_cnt1].amount[_cnt2].value.sub(_withdrawAmount);
                    }
                } 
            }
        }
    }

    /**
     * Function that allows the contract owner to deposit a specified amount of a specific token to the treasury balance.
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
        // loop through the list of tokens of the treasury
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
            // add the new token with the depositAmount as value to the treasury
            treasuryWallet.amount.push(perTreasury);
        }
    }

    /**
     * Function that allows the contract owner to withdraw a specified amount of a specific token from the treasury balance.
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
        // loop through the list of tokens of the treasury
        for(uint256 cnt = 0; cnt < treasuryWallet.amount.length; cnt++) {
            // if the token is the same as the tokenAddress
            if(treasuryWallet.amount[cnt].tokenAddress == _tokenAddress) {
                uint256 _balance = _token.balanceOf(treasuryWallet.walletAddress);
                // require that the Treasury has enough balance to withdraw
                require(_withdrawAmount <= _balance, "Contract has not enough tokens");
                // require that the treasury has enough balance to withdraw
                require(_withdrawAmount <= treasuryWallet.amount[cnt].value, "You cannot withdraw this amount");
                // require that the contract has enough allowance from the Treasury
                require(_token.allowance(treasuryWallet.walletAddress, address(this)) >= _withdrawAmount, "Allowance Error: walletAddress does not have enough allowance from the token contract");
                // require that the tokens transfer successfully
                require(_token.transferFrom(treasuryWallet.walletAddress, owner, _withdrawAmount), "TransferFrom Error");
                // emit the WithdrawTreasury event to log the transaction
                emit WithdrawTreasuryEvent(_tokenAddress, _withdrawAmount);
                // update the balance of the token of the treasury
                treasuryWallet.amount[cnt].value = treasuryWallet.amount[cnt].value.sub(_withdrawAmount);
            }
        }
    }

    /**
     * Function that allows the contract owner to update the balance of a wallet and treasury
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
        // declare the tokenExists variable to check if the treasury has a balance of the token
        bool tokenExists = false;
        // loop through the list of tokens of the treasury
        for(uint256 cnt = 0; cnt < treasuryWallet.amount.length; cnt++) {
            // if the token is the same as the tokenAddress
            if(treasuryWallet.amount[cnt].tokenAddress == _tokenAddress) {
                // if the decreaseUserBalance is false
                if(_decreaseUserBalance == false) {
                    // decrease the treasury's balance with the updateAmount
                    treasuryWallet.amount[cnt].value = treasuryWallet.amount[cnt].value.sub(_updateAmount);
                // if the decreaseUserBalance is true
                } else {
                    // increase the treasury's balance with the updateAmount
                    treasuryWallet.amount[cnt].value = treasuryWallet.amount[cnt].value.add(_updateAmount);
                }
                tokenExists = true;
            }
        }
        // if the token does not exists
        if(tokenExists == false) {
            treasuryAmount memory perTreasury = treasuryAmount(_tokenAddress, _updateAmount);
            // add the new token with the updateBalance as value to the treasury
            treasuryWallet.amount.push(perTreasury);
        }
        // emit the UpdateBalance event to log the transaction
        emit UpdateBalanceEvent(_walletAddress, _tokenAddress, _updateAmount, _decreaseUserBalance);
    }

    /**
      Function that allows the contract owner to add a new token to the allowedTokens
     * @param _tokenAddress The address of the token being added
    */
    function addToken(address _tokenAddress) external onlyOwner {
        // require that the tokenAddress is a valid crypto address
        require(_tokenAddress != address(0), "Invalid token address");
        // check if there is any token in the list
        if(allowedTokens.length > 0) {
            // loop through the list of tokens
            require(isTokenAdded(_tokenAddress) == false, "Token is already on the allowedTokens list");
        }
        // if the token does not exist in the list, add it to the list
        allowedTokens.push(_tokenAddress);
        // emit the TokenAdded event to log the transaction
        emit TokenAddedEvent(_tokenAddress);
    }

    /**
      Function that allows the contract owner to remove a token from the allowedTokens
     * @param _tokenIndex The index of the token being removed
    */
    function removeToken(uint256 _tokenIndex) external onlyOwner {
        // require the index to be valid
        require(_tokenIndex < allowedTokens.length, "tokenIndex out of range");
        // loop through the tokens from the tokenIndex
        for (uint i = _tokenIndex; i < allowedTokens.length - 1; i++){
            // move each token down by one
            allowedTokens[i] = allowedTokens[i + 1];
        }
        // remove the last element
        allowedTokens.pop();
        // emit the TokenRemoved event to log the transaction
        emit TokenRemovedEvent(_tokenIndex);
    }

    /**
      Function that allows the contract owner to pause the contract
      This prevents any further transactions to be made until the contract is resumed
    */
    function pause() external onlyOwner {
        // require that the contract is not paused
        require(!paused, "The contract is paused");
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
        require(paused, "The contract is not paused");
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
        require(_newTreasury != treasuryWallet.walletAddress, "New Treasury cannot be the current Treasury");
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