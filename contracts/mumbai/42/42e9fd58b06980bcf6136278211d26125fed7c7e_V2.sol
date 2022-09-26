/**
 *Submitted for verification at polygonscan.com on 2022-09-26
*/

contract V2 {
    

    address public minter;
    mapping (address => uint) public balances;
    uint public fees;

    // Events allow clients to react to specific
    // contract changes you declare
    event Sent(address from, address to, uint amount, uint claimedfee);

    // Constructor code is only run when the contract
    // is created


    // Sends an amount of newly created coins to an address
    // Can only be called by the contract creator
    function mint(address receiver, uint amount) public {
        require(msg.sender == minter);
        balances[receiver] += amount;
    }

    // Errors allow you to provide information about
    // why an operation failed. They are returned
    // to the caller of the function.
    error InsufficientBalance(uint requested, uint available);

    // Sends an amount of existing coins
    // from any caller to an address
    function send(address receiver, uint amount) public {
        if (amount > balances[msg.sender])
            revert InsufficientBalance({
                requested: amount,
                available: balances[msg.sender]
            });

        uint fee= (amount/10000)*5;
        uint value= amount- fee;
        balances[msg.sender] -= amount;
        balances[receiver] += value;
        fees+=fee;
        emit Sent(msg.sender, receiver, amount, fee);
    }
}