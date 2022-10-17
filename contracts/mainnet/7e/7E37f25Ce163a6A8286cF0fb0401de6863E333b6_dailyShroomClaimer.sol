/**
 *Submitted for verification at polygonscan.com on 2022-10-17
*/

// File: contracts/interfaces/IShroomController.sol

pragma solidity ^0.8.0;



interface IShroomController {
    function getShroom(uint256 _number,string memory _name,address _to)external;
    function getRemaining(string memory _name,address _to)external;
}
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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// File: contracts/dailyShroomClaimer/dailyShroomClaimer.sol

pragma solidity ^0.8.0;





contract dailyShroomClaimer is Ownable, Pausable {
    IShroomController controller;
    address public signer;

    constructor(IShroomController _controller, address _signer)Ownable() Pausable(){
        controller = _controller;
        signer = _signer;
    }


    mapping(bytes32 => bool) public isSignatureUsed;
    mapping(address => uint256) public userLastClaim;
    // user=> tokenIdLastClaim
    mapping(uint256 => uint256) public  tokenIdLastClaim;
    mapping(address => uint256) public userNonce;


    event RequestProcessed(uint256 _amount, address _user, string _requestId, uint8 _v, bytes32 _r, bytes32 _s, bool _status);


    function addSigner(address _signer) external onlyOwner {
        signer = _signer;

    }

    function claim(uint256 _amount, address _user, string memory _requestId, uint256 _expireTime, uint8 _v, bytes32 _r, bytes32 _s) external {
        uint256 currentTime = block.timestamp;
        require(currentTime - userLastClaim[_user] >= 1 days, "User can claim only after 1 day");
        require(currentTime <= _expireTime, "Signature expired");
        validateSignature(_amount, _user, 0, _requestId, _expireTime, _v, _r, _s);
        userLastClaim[_user] = currentTime;
        controller.getShroom(_amount, "dailyRewardClaimer", _user);
        emit RequestProcessed(_amount, _user, _requestId, _v, _r, _s, true);
    }

    function claimSingle(uint256 _amount, address _user, uint256 _tokenId, string memory _requestId, uint256 _expireTime, uint8 _v, bytes32 _r, bytes32 _s) public {
        uint256 currentTime = block.timestamp;
        require(currentTime - tokenIdLastClaim[_tokenId] >= 1 days, "User can claim only after 1 day for the tokenid");
        require(currentTime <= _expireTime, "Signature expired");
        validateSignature(_amount, _user, _tokenId, _requestId, _expireTime, _v, _r, _s);
        tokenIdLastClaim[_tokenId] = currentTime;
        controller.getShroom(_amount, "dailyRewardClaimer", _user);
        emit RequestProcessed(_amount, _user, _requestId, _v, _r, _s, true);
    }


    function validateSignature(uint256 _amount, address _user, uint256 _tokenId, string memory _requestId, uint256 _expireTime, uint8 _v, bytes32 _r, bytes32 _s) internal {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 messageHash;
        uint256 nonce = userNonce[_user];
        if (_tokenId == 0) {
            messageHash = keccak256(abi.encodePacked(_amount, _user, _requestId, _expireTime, nonce, "POLYGON137V2"));
        }
        else {
            messageHash = keccak256(abi.encodePacked(_amount, _user, _tokenId, _requestId, _expireTime, nonce, "POLYGON137V2"));
        }
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, messageHash));
        address signer_ = ecrecover(prefixedHashMessage, _v, _r, _s);
        bytes32 sig = keccak256(abi.encodePacked(_v, _r, _s));
        userNonce[_user] = nonce + 1;
        require(!isSignatureUsed[sig], "Signature already used");
        require(signer_ == signer, "Signature invalid");
        isSignatureUsed[sig] = true;

    }

}