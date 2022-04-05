/**
 *Submitted for verification at polygonscan.com on 2022-04-05
*/

// SPDX-License-Identifier: GPL-3.0
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/test.sol



pragma solidity >=0.8.0 <0.9.0;


contract CryptoBet is Ownable{

    uint public betCost = 5000000000000000;
    uint private balance;
    uint private randomNonce = 0;
    uint public evenCount=0;
    uint public oddCount=0;
    enum Result { NONE, LOSE, WIN, DRAW }

    struct Bet{
        address participant;
        uint value;
        Result result;
    }

    Bet[] private bets;

    event Winner(Result result, uint award);

    constructor() {
    }


    modifier withoutParticipanting(){
        for(uint i=0; i< bets.length; i++){
            require(msg.sender != bets[i].participant, "you are already participating");
        }
        _;
    }
    

    function makeBet(uint _value) external payable withoutParticipanting(){
        require(msg.value == betCost,"Incorrect amount");
        Bet memory bet;
        bet.participant = msg.sender;
        bet.value = _value;
        bet.result = Result.LOSE;
        bets.push(bet);
        balance = balance + msg.value;

        if(bets.length == 2){
            Bet memory bet1 = bets[0];
            Bet memory bet2 = bets[1];
            delete bets;
        
            transferFeeToOwner(); 

            uint winnersCount = 0;
            uint award = 0;
            uint winnerValue = getPRN(77) % 2;

            if(winnerValue == 1){
                oddCount++;
            }
            else{
                evenCount++;
            }

            if(winnerValue == bet1.value){
                    bet1.result= Result.WIN;
                    winnersCount++;
            }

            if(winnerValue == bet2.value){
                    bet2.result= Result.WIN;
                    winnersCount++;
            }


            if( winnersCount == 0){
                award = balance / 2;
                balance -=  award;
                (bool b1t, ) =  payable(bet1.participant).call{value: award}("");
                require(b1t, "Transfer to participant failed");
                balance -=  award;
                (bool b2t, ) =  payable(bet2.participant).call{value: award}("");
                require(b2t, "Transfer to participant failed");
            }
            else{ 
                award = balance / winnersCount;
                if(bet1.result == Result.WIN){
                    balance -=  award;
                    (bool b1t, ) =  payable(bet1.participant).call{value: award}("");
                    require(b1t, "Transfer to participant failed");
                }
                if(bet2.result == Result.WIN){
                    balance -=  award;
                    (bool b2t, ) =  payable(bet2.participant).call{value: award}("");
                    require(b2t, "Transfer to participant failed");

                }
            }
            
            emit Winner(bet1.participant == msg.sender ? bet1.result : bet2.result, award);
        }
    }


    function transferFeeToOwner() private {   
        uint amount = balance * 2 / 100;
        balance -=  amount;
        (bool os, ) = payable(owner()).call{value: amount}("");
        require(os, "Transfer fee to owner failed");
    }

    function balanceOf() external view onlyOwner returns (uint){
        return balance;
    }

    function setBetCost(uint _newCost) external onlyOwner{
        betCost = _newCost;
    }

     function getPRN(uint256 _module) internal returns (uint256) {
        randomNonce = (randomNonce == ((2**256) - 1)) ? 0 : randomNonce + 1;
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    randomNonce +
                        block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number
                )
            )
        );
        return (seed - ((seed / (1 * 10**(_module))) * (1 * 10**(_module))));
    }
}