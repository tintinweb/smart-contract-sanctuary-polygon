/** 
   WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW   
 N0xxxxxxxxxxxxxddxxxxxxxxxxxxxxxxxxxxxxxxxxxxx0N 
W0occcccccccc:,....';cccccccccccccccccccccccccco0 
W0lccccccc;'..  ..   .';:ccccccccccccccccccccccl0 
W0lccccc:'   .';::;'.   .,:ccccccccccccccccccccl0 
W0lccccc:.  'cccccccc,. ..;ccc:;:ccccccccccccccl0W
W0lccccc:. .;cccccccc:'.,;;;'.  ..,:cccccccccccl0W
W0lccccc:.  ,cccccccc:;'...  ....   .';ccccccccl0W
W0lccccc:.  ..,:cc:;'.   ..';:cc:;'.  .;cccccccl0W
W0lcccccc:,..  ....  ..';:ccccccccc;.  ,cccccccl0W
W0lccccccccc:;'.  ..,:;'.';cccccccc;.  ,cccccccl0W
W0lccccccccccccc::ccc:.  .':ccccccc,   ,cccccccl0W
W0lcccccccccccccccccc:'    .',::;'.   .;cccccccl0W
 0lcccccccccccccccccccc;'..    .   .';:ccccccccl0 
 Kocccccccccccccccccccccccc:,....';cccccccccccco0 
 WKOkkkkkkdlccccccccldkkkkkkkkkkkkkkkkkkkkkkkkOKW 
         XxlccccclokKNW                           
        WOlccccox0XW                              
       WKdccldOXW                                 
       NxlokKN                                    
      WKk0NW                                      
       WW                                         
                    PolyChat

         Try it out on https://polychat.xyz
 */
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PolyChat is Ownable {
    mapping(address => bytes) private publicKeys;
    mapping(address => string[]) private _messages;
    mapping(address => uint256) private _messagingFee;
    mapping(address => mapping(address => uint256))
        private _messagingFeeWhiteList;
    mapping(address => address[]) public messagingFeeSenders;
    uint256 private _globalMessagingFee;

    constructor() {
        _globalMessagingFee = 10**17; //0.1 ETH
        emit NewGlobalMessagingFee(_globalMessagingFee);
    }

    event Message(address _sender, address indexed _recepient, string _message);
    event NewPublicKey(address indexed _account, bytes _publicKey);
    event NewGlobalMessagingFee(uint256 _messagingFee);
    event NewMessagingFee(address indexed _account, uint256 _messagingFee);
    event NewWhitelistMessagingFee(
        address indexed _account,
        address fromAccount,
        uint256 _messagingFee
    );

    function setGlobalMessagingFee(uint256 _newMessagingFee) public onlyOwner {
        _globalMessagingFee = _newMessagingFee;
        emit NewGlobalMessagingFee(_newMessagingFee);
    }

    function setPublicKey(bytes memory _public_key) public {
        publicKeys[msg.sender] = _public_key;
        emit NewPublicKey(msg.sender, _public_key);
    }

    function publicKeyOf(address _address) public view returns (bytes memory) {
        return publicKeys[_address];
    }

    function setMessagingFee(uint256 _newFee) public {
        _messagingFee[msg.sender] = _newFee;
        emit NewMessagingFee(msg.sender, _newFee);
    }

    function setWhiteListFee(address _from, uint256 _newFee) public {
        _messagingFeeWhiteList[msg.sender][_from] = _newFee;
        messagingFeeSenders[msg.sender].push(_from);
        emit NewWhitelistMessagingFee(msg.sender, _from, _newFee);
    }

    function messagingFeeFor(address _address) public view returns (uint256) {
        if (_messagingFeeWhiteList[_address][msg.sender] > 0) {
            return
                _messagingFeeWhiteList[_address][msg.sender] +
                _globalMessagingFee;
        } else if (_messagingFee[_address] > 0) {
            return _messagingFee[_address] + _globalMessagingFee;
        } else {
            return _globalMessagingFee;
        }
    }

    function globalMessagingFee() public view returns (uint256) {
        return _globalMessagingFee;
    }

    function sendMessageTo(string memory _message, address payable _address)
        public
        payable
    {
        require(
            bytes(publicKeys[_address]).length > 0,
            "Recipient public key not added"
        );
        require(
            bytes(publicKeys[msg.sender]).length > 0,
            "You must register a public key to send a message"
        );
        if (_messagingFeeWhiteList[_address][msg.sender] > 0) {
            require(
                msg.value ==
                    _messagingFeeWhiteList[_address][msg.sender] +
                        _globalMessagingFee,
                "Incorrect messaging fee"
            );
        } else if (_messagingFee[_address] > 0) {
            require(
                msg.value == _messagingFee[_address] + _globalMessagingFee,
                "Incorrect messaging fee"
            );
        } else {
            require(
                msg.value == _globalMessagingFee,
                "Incorrect messaging fee"
            );
        }
        _address.transfer(msg.value - _globalMessagingFee);
        emit Message(msg.sender, _address, _message);
    }

    function withdraw(address payable _address, uint256 _amount)
        public
        onlyOwner
    {
        _address.transfer(_amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
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