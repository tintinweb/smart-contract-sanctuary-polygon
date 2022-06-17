// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./interfaces/IPoolFactory.sol";
import "./interfaces/ITicket.sol";
import "./interfaces/IVesting.sol";
import "./extensions/KLAYDAOWhitelist.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract IDOPool is Ownable, Pausable, KLAYDAOWhitelist {

    // bytes32 keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;

    // // address of vrfCoord
    // address public vrfCoord = 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255;

    // // address of Link token
    // address public linkAddr = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;

    // The token to buy ticket
    address public USDC;

    // The token being sold
    address public token; 

    // The ticket to join ido
    address public ticket;

    // address of vesting schedule
    address public vesting;

    // Address where funds are collected
    address public fundingWallet;

    // Timestamps when token started to sell
    uint256 public openTime = block.timestamp;

    // Timestamps when token stopped to sell
    uint256 public closeTime;

    // Amount of token sold
    uint256 public tokenSold = 0;

    // Time Stop buy/mint ticket
    uint256 public ticketCloseTime;

    // Time start Vesting
    uint256 public vestingStartTime;

    // Cliff time of Vesting Schedule
    uint256 public vestingCliffTime;

    // Duration of Vesting Schedule
    uint256 public vestingDuration;

    // 
    uint256 public amountIDOToken;

    // TGE Vesting
    uint128 public vestingTGE;


    // Number of token user purchased
    mapping(address => uint256) public userPurchased;

    // Number of ticket user purchased/minted
    mapping(uint256 => mapping(address => uint256)) public userTicket;


    // Pool extensions
    bool public useWhitelist = true;

    // Init
    bool public init;

    // -----------------------------------------
    // Lauchpad Starter's event
    // -----------------------------------------
    event PoolCreated(
        address token,
        uint256 openTime,
        uint256 closeTime,
        address offeredCurrency,
        address wallet,
        address owner
    );

    event RefundedIcoToken(address wallet, uint256 amount);
    event SetPoolExtentions(bool _whitelist);
    event UpdateRoot(bytes32 _root);
    event SetCloseTime(uint256 _closeTime);
    event SetOpenTime(uint256 _openTime);
    event MintTicket(address indexed _to, uint256 _totalStaked, uint256 _id, uint256 _quantity);
    event BuyTicket(address indexed _to, uint256 _amount, uint256 _id, uint256 _quantity);
    event SwapToToken(address indexed _user, uint256 _amountIDOtoken, uint256 _amountUSDC, uint256 _idTicket, uint256 _totalTicket);
    event SetUpVestingInformation(uint256 _start, uint256 _cliff, uint256 _duration, uint256 _TGE);

    // constructor() VRFConsumerBase(vrfCoord, linkAddr) {
    //     fee = 0.1 * 10**18;
    // }

    /**
     * @dev fallback function
     */
    fallback() external {
        revert();
    }

    /**
     * @dev fallback function
     */
    receive() external payable {
        revert();
    }

    // /**
    //  * @param _token Address of the token being sold
    //  * @param _duration Duration of ICO Pool
    //  * @param _openTime When ICO Started
    //  * @param _usdc Address of offered token
    //  */
    function addressInitialize(
        address _token,
        address _usdc, 
        address _ticketAddress, 
        address _vestingAddress 
    ) external {
        require(init == false, "POOL::INITIALIZED");

        USDC = _usdc;
        token = _token;
        ticket = _ticketAddress;
        vesting = _vestingAddress;
    }

    function uintInitialize(
        uint256 _amountIDOtoken,
        uint256 _openTime,
        uint256 _duration,
        uint256 _ticketCloseTime
    ) external {
        require(init == false, "POOL::INITIALIZED");

        openTime = _openTime;
     
        amountIDOToken = _amountIDOtoken;
        closeTime = _openTime + _duration;
        ticketCloseTime = _ticketCloseTime;

        _transferOwnership(tx.origin);
        
        init = true;
    }

    /**
     * @notice Owner add root to verify.
     * @param _root root of merkle tree
     */
    function updateRoot(bytes32 _root) external onlyOwner {
        root = _root;

        emit UpdateRoot(_root);
    }

    /**
     * @notice Owner add root to verify.
     * @param _wallet root of merkle tree
     */
    function updateFundingWallet(address _wallet) external onlyOwner {
        fundingWallet = _wallet;

    }

    /**
     * @notice Owner can set Vesting information
     * @param _start Start vesting time
     * @param _cliff Cliff vesting time
     * @param _duration Vestingg duration
     * @param _TGE TGE percentage
     */
    function setUpVestingInformation(uint256 _start, uint256 _cliff, uint256 _duration, uint128 _TGE) external onlyOwner {
        vestingStartTime = _start;
        vestingCliffTime = _cliff;
        vestingDuration = _duration;
        vestingTGE = _TGE;

        emit SetUpVestingInformation(_start, _cliff, _duration, _TGE);
    }

    function buyTicket(
        address _to,
        uint256 _amount,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data,
        bytes32[] memory proof
    ) public whenNotPaused {

        require(_validPurchase(), "POOL::TICKET_ENDED");
        require(_quantity > 0, "POOL::CANT MINT 0 TICKET");
        require(_amount > 0, "POOL::DONT HAVE ENOUGH TOKEN TO BUY TICKET");
        require(_to != address(0), "POOL::CANT MINT 0 TICKET");

        _verifyAllowance(msg.sender, _amount);

        require(_verifyMintTicket(_to, _amount, _id, _quantity, proof), "POOL:INVALID_MERKLE");

        _forwardTokenFunds(_amount);

        ITicket(ticket).mint(_to, _id, _quantity, _data);

        userTicket[_id][_to] += _quantity;

        emit BuyTicket(_to, _amount, _id, _quantity);
    }


    function swapToToken(
        address _user, 
        uint256 _amountIDOtoken, 
        uint256 _amountUSDC, 
        uint256 _idTicket,
        uint256 _totalTicket,
        bytes32[] memory proof
    ) external whenNotPaused {
        
        require (block.timestamp > ticketCloseTime, "POOL::TICKET_PURCHASE_IS_NOT_OVER"); 
        require(vestingStartTime != 0, "POOL::INVALID_VESTING_START_TIME");
        require(vestingCliffTime != 0, "POOL::INVALID_VESTING_CLIFF_TIME");
        require(vestingDuration != 0, "POOL::INVALID_VESTING_DURATION");
        require(_verifyResult(_user, _amountIDOtoken, _amountUSDC, _idTicket, _totalTicket, proof), "POOL:INVALID_MERKLE");
        

        if (_amountUSDC > 0) { 
            IERC20(USDC).transfer(_user, _amountUSDC);
        }
    
        burnTicket(address(this), _idTicket, _totalTicket);

        if (_amountIDOtoken > 0) {
            IVesting(vesting).createVesting(_user, token, vestingCliffTime, vestingStartTime, vestingDuration, _amountIDOtoken, vestingTGE);
        }

        _updatePurchasingState(_amountIDOtoken);
        
        userTicket[_idTicket][msg.sender] -= _totalTicket;
        userPurchased[_user] = userPurchased[_user] + _amountIDOtoken;
        
        emit SwapToToken(_user, _amountIDOtoken, _amountUSDC, _idTicket, _totalTicket);
    }

    function burnTicket(address _from, uint256 _id, uint256 _quantity) internal {
        ITicket(ticket).burn(_from, _id, _quantity);
    }

    /**
     * @notice Return true if pool has ended
     * @dev User cannot purchase / trade tokens when isFinalized == true
     * @return true if the ICO Ended.
     */
    function isFinalized() public view returns (bool) {
        return block.timestamp >= closeTime;
    }

    /**
     * @notice Owner can receive their remaining tokens when ICO Ended
     * @dev  Can refund remainning token if the ico ended
     */
    function refundRemainingUSDC()
        external
        onlyOwner
    {
        require(isFinalized(), "POOL::ICO_NOT_ENDED");
        require(IERC20(USDC).balanceOf(address(this)) > 0, "POOL::EMPTY_BALANCE");
        require(fundingWallet != address(0), "ICOFactory::ZERO_ADDRESS");

        uint256 remain = IERC20(USDC).balanceOf(address(this));
        IERC20(USDC).transfer(address(fundingWallet), remain);
        
    }

    /**
     * @dev Determines how Token is stored/forwarded on purchases.
     */
    function _forwardTokenFunds(uint256 _amount) internal {
        IERC20(USDC).transferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @param _tokens Value of sold tokens
     */
    function _updatePurchasingState(uint256 _tokens)
        internal
    {
        tokenSold = tokenSold + _tokens;
    }

    // @return true if the transaction can buy tokens
    function _validPurchase() internal view returns (bool) {
        bool withinPeriod =
            block.timestamp >= openTime && block.timestamp <= ticketCloseTime;
        return withinPeriod;
    }

    function _verifyAllowance(
        address _user,
        uint256 _amount
    ) private view {
        IERC20 tradeToken = IERC20(USDC);
        uint256 allowance = tradeToken.allowance(_user, address(this));
        require(allowance >= _amount, "POOL::TOKEN_NOT_APPROVED");
    }

    
    /**
     * @dev Verify permission of minting ticket
     * @param proof merkle tree proof
     * @param _id nft id ticket
     * @param _candidate Address of buyer
     * @param _quantity amount ticket want to mint
     * @param _amount total CODE stake
     */
    function _verifyMintTicket(
        address _candidate,
        uint256 _amount,
        uint256 _id,
        uint256 _quantity,
        bytes32[] memory proof
    ) private view returns (bool) {
    
        return (verifyMintTicket(_candidate, _amount, _id, _quantity, proof));
    }


    /**
     * @dev Verify permission of minting ticket
     * @param proof merkle tree proof
     * @param _idTicket nft id ticket
     * @param _candidate Address of buyer
     * @param _totalTicket amount Ticket
     * @param _amountIDOtoken total IDO token will receive
     * @param _amountUSDC total USDC token will receive
     */
    function _verifyResult(
        address _candidate,
        uint256 _amountIDOtoken,
        uint256 _amountUSDC,
        uint256 _idTicket,
        uint256 _totalTicket,
        bytes32[] memory proof
    ) private view returns (bool) {
        
        return (verifyResult(_candidate, _amountIDOtoken, _amountUSDC, _idTicket, _totalTicket, proof));
    }



    //--------------------------------------------------------------
    //CHAINLINK
    //--------------------------------------------------------------

    // /**
    //  * Requests randomness
    //  */
    // function getRandomNumber() public returns (bytes32 requestId) {
    //     require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
    //     return requestRandomness(keyHash, fee);
    // }

    // /**
    //  * Callback function used by VRF Coordinator
    //  */
    // function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    //     randomResult = randomness;
    // }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.1;

interface IPoolFactory {
    function getTier() external view returns (address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ITicket is IERC1155 {

    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) external returns(uint256, uint256);
    
    function burn(
        address _from,
        uint256 _id,
        uint256 _quantity
    ) external;

    function initialize(string memory _name, string memory _symbol, address _minter) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


interface IVesting {

   function createVesting(
        address _user, 
        address _token,
        uint256 _cliff, 
        uint256 _start, 
        uint256 _duration, 
        uint256 _amountTotal,
        uint128 _TGE
    ) external;
    
    function setPoolVesting(address _pool) external;
    

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// Signature Verification

contract KLAYDAOWhitelist {

    bytes32 public root;

    bytes32 public rootBuy;
    

    function verifyMintTicket(
        address _candidate,
        uint256 _amount,
        uint256 _id,
        uint256 _quantity,
        bytes32[] memory proof
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_candidate, _amount, _id, _quantity));

        return MerkleProof.verify(proof, root, leaf);
    }

    function verifyResult(
        address _candidate,
        uint256 _amountIDOtoken,
        uint256 _amountUSDC,
        uint256 _idTicket,
        uint256 _totalTicket,
        bytes32[] memory proof
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_candidate, _amountIDOtoken, _amountUSDC, _idTicket, _totalTicket));

        return MerkleProof.verify(proof, root, leaf);
    }


    // // Using Openzeppelin ECDSA cryptography library
    // function getMessageHash(
    //     address _candidate,
    //     uint256 _maxAmount,
    //     uint256 _minAmount
    // ) public pure returns (bytes32) {
    //     return keccak256(abi.encodePacked(_candidate, _maxAmount, _minAmount));
    // }

    // function getClaimMessageHash(
    //     address _candidate,
    //     uint256 _amount
    // ) public pure returns (bytes32) {
    //     return keccak256(abi.encodePacked(_candidate, _amount));
    // }

    // // Verify signature function
    // function verify(
    //     address _signer,
    //     address _candidate,
    //     uint256 _maxAmount,
    //     uint256 _minAmount,
    //     bytes memory signature
    // ) public pure returns (bool) {
    //     bytes32 messageHash = getMessageHash(_candidate, _maxAmount, _minAmount);
    //     bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

    //     return getSignerAddress(ethSignedMessageHash, signature) == _signer;
    // }

    // // Verify signature function
    // function verifyClaimToken(
    //     address _signer,
    //     address _candidate,
    //     uint256 _amount,
    //     bytes memory signature
    // ) public pure returns (bool) {
    //     bytes32 messageHash = getClaimMessageHash(_candidate, _amount);
    //     bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

    //     return getSignerAddress(ethSignedMessageHash, signature) == _signer;
    // }

    // function getSignerAddress(bytes32 _messageHash, bytes memory _signature) public pure returns(address signer) {
    //     return ECDSA.recover(_messageHash, _signature);
    // }

    // // Split signature to r, s, v
    // function splitSignature(bytes memory _signature)
    //     public
    //     pure
    //     returns (
    //         bytes32 r,
    //         bytes32 s,
    //         uint8 v
    //     )
    // {
    //     require(_signature.length == 65, "invalid signature length");

    //     assembly {
    //         r := mload(add(_signature, 32))
    //         s := mload(add(_signature, 64))
    //         v := byte(0, mload(add(_signature, 96)))
    //     }
    // }

    // function getEthSignedMessageHash(bytes32 _messageHash)
    //     public
    //     pure
    //     returns (bytes32)
    // {
    //     return ECDSA.toEthSignedMessageHash(_messageHash);
    // }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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