// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC20Interface {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract TokenTransferContract {
    // STATE VARIABLES
    // only the person who deployed the contract (owner) will be able to add verified tokens
    address public owner;

    // create a mapping to check if our token is verified or not (mapping of address to bool of verifiedTokens that is private) (only transfer verified tokens)
    mapping(address => bool) private verifiedTokens;

    // list of verified tokens added to this array
    address[] public verifiedTokensList;

    struct Transaction {
        address sender;
        address receiver;
        uint256 amount;
        string message;
    }

    // keep track of the transfers made on the blockchain, every time a transfer completes, this event will trigger

    event TransactionCompleted(
        address indexed sender,
        address indexed receiver,
        uint256 amount,
        string message
    );

    // the function that runs when/once the contract is deployed, whoever deploys the contract will be the owner of the contract
    constructor() {
        owner = msg.sender;
    }

    // MODIFIER FUNCTIONS
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the owner of this contract can call this function"
        );
        _;
    }

    modifier onlyVerifiedToken(address _token) {
        // check the verifiedTokens array for a particular token address
        require(verifiedTokens[_token], "Token is not verified.");
        _;
    }

    // function to allow owner to add a token to the verified list
    function addVerifyToken(address _token) public onlyOwner {
        verifiedTokens[_token] = true;
        verifiedTokensList.push(_token);
    }

    // function to allow owner to remove a token from the verified list
    function removeVerifyToken(address _token) public onlyOwner {
        // first: check if the token to be removed is actually already verified (no need to proceed otherwise)
        require(
            verifiedTokens[_token] == true,
            "This token is not already verified"
        );
        verifiedTokens[_token] = false;
        // loop through the list to find the _token, then remove it
        for (uint256 i = 0; i < verifiedTokensList.length; i++) {
            if (verifiedTokensList[i] == _token) {
                verifiedTokensList[i] = verifiedTokensList[
                    verifiedTokensList.length - 1
                ];
                verifiedTokensList.pop();
                break;
            }
        }
    } // NOTE: I don't understand how this array manipulation works...

    // get a list of the token contracts that are verified on the transfer contract (returns the array of verified tokens (addresses))
    function getVerfiedTokens() public view returns (address[] memory) {
        return verifiedTokensList;
    }

    // transfer function - need to know: who to send to (token contract address), amount to send, and message to go with it
    function transfer(
        IERC20Interface token,
        address to,
        uint256 amount,
        string memory message
    ) 
        public 
        onlyVerifiedToken(address(token)) 
        returns (bool)
    {
        // ensure sender actually has enough token
        uint256 senderBalance = token.balanceOf(msg.sender);
        require(senderBalance >= amount, "insufficient balance.");
        
        // transfer token using transferFrom() method
        bool success = token.transferFrom(msg.sender, to, amount);
        require(success, "Transfer failed.");

        // set transaction to memory
        Transaction memory transaction = Transaction({
            sender: msg.sender,
            receiver: to,
            amount: amount,
            message: message
        });

        // emit to the blockchain
        emit TransactionCompleted(
            msg.sender,
            transaction.receiver,
            transaction.amount,
            transaction.message
        );

        //
        return true;
    }
}