/**
 *Submitted for verification at polygonscan.com on 2022-01-31
*/

pragma solidity ^0.5.0;

contract TipJar {
    mapping(bytes32 => bool) public isJar;
    mapping(bytes32 => Jar) public jar;

    struct Jar {
        bytes32 id;
        address owner;
        uint256 balance;
    }

    event jarCreation (
        bytes32 jarId,
        address owner
    );

    event jarDeletion (
        bytes32 jarId,
        address owner
    );

    event jarTransfer (
        bytes32 jarId,
        address owner,
        address receiver
    );

    event donation (
        bytes32 jarId,
        address sender,
        uint256 amount
    );

    event withdrawal (
        bytes32 jarId,
        address owner,
        address receiver,
        uint256 amount
    );

    // Ensure the message sender owns the tipjar
    modifier onlyOwner(bytes32 id) {
        require(msg.sender == jar[id].owner);
        _;
    }

    /** @dev Function to determine if an jar id is allowed
      * @param id - potential jar id that gets checked
      */
    function isValidId(bytes32 id) public pure returns (bool) {
        if (id.length < 3) {
            return false;
        }
        for (uint i = 0; i < id.length; i++) {
            if (id[i] >= "a" && id[i] <= "z") {
                continue;
            } else if (id[i] >= "A" && id[i] <= "z") {
                continue;
            } else if (id[i] >= "0" && id[i] <= "9") {
                continue;
            } else if (id[i] == 0x00 && i >= 3) {
                return true;
            } else {
                return false;
            }
        }
        return true;
    }

    /** @dev Creates a tip jar with the specified id and the message sender as the owner
      * @param id - id that the jar gets created at
      */
    function createTipJar(bytes32 id) public {
        require (isValidId(id)); // Ensures id is allowed
        require (!isJar[id]); // Ensures id hasn't been used yet

        isJar[id] = true;
        jar[id] = Jar ({
            id: id,
            owner: msg.sender,
            balance: 0
        });

        emit jarCreation(id, msg.sender);
    }

    /** @dev Sends an amount to the jar id
      * @param id - id for the jar that gets donated to
      */
    function donate(bytes32 id) external payable {
        require (isValidId(id));
        require (isJar[id]);

        jar[id].balance += msg.value;

        emit donation(id, msg.sender, msg.value);
    }

    /** @dev Withdraws a specified amount to the receiver address
      * @param id - jar id to withdraw from
      * @param receiver - address to send to
      * @param amount - amount to withdraw
      */
    function withdraw(bytes32 id, address payable receiver, uint amount) public onlyOwner(id) {
        require (isValidId(id));
        require (isJar[id]);
        require (jar[id].balance >= amount);

        address owner = jar[id].owner;

        jar[id].balance -= amount;
        receiver.transfer(amount);

        emit withdrawal(id, owner, receiver, amount);
    }

    /**
      * @dev Deletes the specified tip jar
      * @param id - id for the jar that gets deleted
      */
    function deleteTipJar(bytes32 id) public onlyOwner(id) {
        require (isValidId(id));        
        require (isJar[id]);
        require (jar[id].balance == 0);

        address owner = jar[id].owner;

        delete jar[id];
        delete isJar[id];

        emit jarDeletion(id, owner);
    }

    /**
      * @dev Transfers the specified tip jar to a new owner
      * @param id - id for the jar that gets moved
      * @param receiver - new owner of the jar
      */
    function transferTipJar(bytes32 id, address receiver) public onlyOwner(id) {
        require (isValidId(id));        
        require (isJar[id]);

        address owner = jar[id].owner;

        jar[id].owner = receiver;

        emit jarTransfer(id, owner, receiver);
    }
}