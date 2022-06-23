/**
 *Submitted for verification at polygonscan.com on 2022-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13 <0.9.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


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





contract PayHoldersContract is Ownable {
    
    //amount of Matic
    uint256 private _balance;

    // amount of winners
    uint256 private _winners_amount = 2;
    
    //holders
    address payable[] public _holders;
    address[] public _winners;

    function getPayee(address payable[] memory temp_holders) public onlyOwner {
        _holders = temp_holders;
    }

    function clearHolders() public onlyOwner {
        address payable[] memory _temp_holders;
        _holders = _temp_holders;
    }

    function payToHolders() public onlyOwner {
        uint256 amount_to_send;
        if(_holders.length >= _winners_amount){
            amount_to_send = _winners_amount;
        } else {
            amount_to_send = _holders.length;
        }
        _sendReward(amount_to_send);
    }

    function showHolders() public view onlyOwner returns (address payable[] memory) {
        return _holders;
    }

    function showWinners() public view onlyOwner returns (address[] memory) {
        return _winners;
    }


    function _sendReward(uint256 a_members_) internal {
        _shuffle();
        uint256 amount_to_send = _howMuch();
        for (uint256 i = _holders.length - 1; i > (_holders.length - 1 - a_members_); i--) {            
            (bool success, ) = _holders[i].call{value: amount_to_send}("");
            _winners.push(_holders[i]);
            require(success, "Address: unable to send value, recipient may have reverted");
        }
        for (uint256 i = 0; i < a_members_; i++) {            
            _holders.pop();
        }
    }




    function _howMuch() private view returns (uint256) {
        if(_holders.length >= _winners_amount){
            return address(this).balance / _winners_amount;
        } else {
            return address(this).balance / _holders.length;
        }
         
    }


    function _shuffle() internal {
        for (uint256 i = 0; i < _holders.length; i++) {
            uint256 n = i + uint256(keccak256(abi.encodePacked(block.timestamp))) % (_holders.length - i);
            address payable temp = _holders[n];
            _holders[n] = _holders[i];
            _holders[i] = temp;
        }
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }
	
	event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

 
}