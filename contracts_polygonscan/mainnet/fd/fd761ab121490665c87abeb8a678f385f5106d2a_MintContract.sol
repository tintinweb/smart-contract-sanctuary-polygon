/**
 *Submitted for verification at polygonscan.com on 2021-08-23
*/

// File: contracts\INFTContract.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface INFTContract {
    function nfts(uint256 nftId)
        external
        view
        returns (
            uint256,
            string memory,
            string memory,
            uint256,
            bool,
            uint256
        );

    function nftOwners(uint256 nftId) external view returns (address);

    function mint(
        address _from,
        string memory _name,
        string memory _uri
    ) external;

    function burnNFT(uint256 _nftId) external;

    function transferNFT(address _to, uint256 _nftId) external;

    function getNFTLevelById(uint256 _nftId) external returns (uint256);

    function getNFTById(uint256 _nftId)
        external
        returns (
            uint256,
            string memory,
            string memory,
            uint256
        );

    function setNFTLevelUp(uint256 _nftId) external;

    function setNFTURI(uint256 _nftId, string memory _uri) external;

    function ownerOf(uint256 _nftId) external returns (address);

    function balanceOf(address _from) external returns (uint256);

    function upgradeNFT(uint256 _nftId, string memory _uri) external;
}

// File: node_modules\@openzeppelin\contracts\utils\Context.sol


pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin\contracts\access\Ownable.sol


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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol


pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// File: contracts\MintContract.sol

pragma solidity ^0.8.0;




contract MintContract is Ownable {
    INFTContract nft_;

    string NFT_NAME = "GamyFi CERENE NFT";
    string NFT_URI =
        "https://gateway.pinata.cloud/ipfs/QmX2HNqHAbkfusD2dArZEyY85fSXHc4FBNqGBEzWyb7Ya3";

    mapping(address => bool) public invitors;
    mapping(address => uint256) public referrals;

    mapping(address => uint256) public referralIds;
    mapping(uint256 => address) public referees;

    IERC20 gfx_;

    uint256 limit;
    uint256 public gfxLimit;

    event NewInvitor(address referee, address invitor);

    event AwardClaimed(address referee);

    event WithdrawBalance(address target, address token, uint256 amount);

    constructor() {
        limit = 10**7;
        gfxLimit = 10**18;
    }

    function initialize(address _nft, address _gfx) public onlyOwner {
        nft_ = INFTContract(_nft);
        gfx_ = IERC20(_gfx);
    }

    function setLimit(uint256 _digits) public onlyOwner {
        require(_digits > 0, "MintContract: Digits should be over 0");

        limit = 10**_digits;
    }

    function setGFXLimit(uint256 _limit) public onlyOwner {
        require(_limit > 0, "MintContract: Limit should be over 0");

        gfxLimit = _limit;
    }

    function generateReferralId(address _owner) private view returns (uint256) {
        return
            limit +
            (uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, _owner)
                )
            ) % limit);
    }

    function addReferralId(address _owner) private {
        if (referralIds[_owner] == 0) {
            uint256 referralId = generateReferralId(_owner);
            while (referees[referralId] != address(0)) {
                referralId = generateReferralId(_owner);
            }

            referralIds[_owner] = referralId;
            referees[referralId] = _owner;
        }
    }

    function mint() public {
        require(
            nft_.balanceOf(msg.sender) == 0,
            "MintContract: Already have nft"
        );
        require(
            gfx_.balanceOf(msg.sender) >= gfxLimit,
            "MintContract: Must have more than 1 GFX"
        );

        nft_.mint(msg.sender, NFT_NAME, NFT_URI);

        addReferralId(msg.sender);
    }

    function mintFromReferral(uint256 _referralId) public {
        require(
            _referralId != 0 && referees[_referralId] != address(0),
            "MintContract: Invalid ReferralId"
        );
        require(!invitors[msg.sender], "MintContract: Already minted");

        nft_.mint(msg.sender, NFT_NAME, NFT_URI);
        generateRandomGFX(msg.sender);

        nft_.mint(referees[_referralId], NFT_NAME, NFT_URI);
        generateRandomGFX(referees[_referralId]);

        invitors[msg.sender] = true;
        referrals[referees[_referralId]]++;

        addReferralId(msg.sender);

        emit NewInvitor(referees[_referralId], msg.sender);
    }

    function generateRandomGFX(address sender) private {
        uint256[10] memory randomNumbers =
            [
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(1),
                uint256(0),
                uint256(1),
                uint256(0),
                uint256(1),
                uint256(0),
                uint256(0)
            ];
        uint256 randomIndex =
            (uint256(keccak256(abi.encodePacked(block.timestamp, sender))) %
                10);

        if (randomNumbers[randomIndex] == uint256(1)) {
            uint256 amount =
                (uint256(keccak256(abi.encodePacked(block.timestamp, sender))) %
                    100);
            amount = amount * (10**16);

            require(
                gfx_.transfer(sender, amount),
                "MintContract: GFX transfer failed"
            );
        }
    }

    function withdrawBalance(
        address _target,
        address _token,
        uint256 _amount
    ) external onlyOwner {
        require(_target != address(0), "Invalid Target Address");
        require(_token != address(0), "Invalid Token Address");
        require(_amount > 0, "Amount should be bigger than zero");

        IERC20 token = IERC20(_token);
        require(token.transfer(_target, _amount), "Withdraw failed");

        emit WithdrawBalance(_target, _token, _amount);
    }
}