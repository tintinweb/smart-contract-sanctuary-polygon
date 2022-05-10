// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface ICUBENFTFragment {
    function safeMintMulti(
        address _to,
        uint256 _amount,
        uint256[] calldata _attribbutes
    ) external;
}

interface ICUBENFTBox {
    function safeMintMulti(address _to, uint256 _amount) external;
}

contract CUBEClaim is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    address public adminSigner;
    IERC20 public cube;
    IERC20 public usdt;
    ICUBENFTFragment public nftFragment;
    ICUBENFTBox public nftBox;

    mapping(address => mapping(uint256 => bool)) public isClaimed;
    mapping(address => Counters.Counter) public transactionIds;

    string public CLAIM_USDT_SEPARATOR = "CUBE_CLAIM_USDT";
    string public CLAIM_MATIC_SEPARATOR = "CUBE_CLAIM_MATIC";
    string public CLAIM_CUBE_SEPARATOR = "CUBE_CLAIM_CUBE";
    string public CLAIM_NFT_BOX_SEPARATOR = "CUBE_CLAIM_NFT_BOX";
    string public CLAIM_NFT_FRAGMENT_SEPARATOR = "CUBE_CLAIM_NFT_FRAGMENT";
    string public CLAIM_REF_REWARD_SEPARATOR = "CUBE_CLAIM_REF_REWARD";

    event ClaimedRewards(uint256 indexed _nonce, address indexed _to);

    event ClaimedRefReward(uint256 indexed _nonce, address indexed _to);

    event Deposited(address indexed _from, uint256 _amount);

    event SweptUSDT(address indexed _to, uint256 _amount);

    event SweptMATIC(address indexed _to, uint256 _amount);

    constructor() {
        adminSigner = msg.sender;
    }

    // setter
    function setAdminSigner(address _adminSigner) external onlyOwner {
        adminSigner = _adminSigner;
    }

    function config(
        address _usdt,
        address _cube,
        address _nftFragment,
        address _nftBox
    ) external onlyOwner {
        usdt = IERC20(_usdt);
        cube = IERC20(_cube);
        nftFragment = ICUBENFTFragment(_nftFragment);
        nftBox = ICUBENFTBox(_nftBox);
    }

    function deposit() external payable {
        emit Deposited(msg.sender, msg.value);
    }

    function sweepUSDT(address _to) external onlyOwner {
        uint256 amount = usdt.balanceOf(address(this));
        usdt.transfer(_to, amount);

        emit SweptUSDT(msg.sender, amount);
    }

    function sweepMATIC(address _to) external onlyOwner {
        uint256 amount = address(this).balance;
        payable(_to).transfer(amount);

        emit SweptMATIC(msg.sender, amount);
    }

    function claimMany(
        uint256 _dupNonce,
        uint256 _nonce,
        uint256[] calldata _amounts,
        uint256[] calldata _attributes,
        bytes[] memory _adminSignatures
    ) external nonReentrant {
        if (_dupNonce != 0) {
            require(!isClaimed[msg.sender][_dupNonce], "FORBIDDEN_ACTION");
            isClaimed[msg.sender][_dupNonce] = true;
        }

        require(!isClaimed[msg.sender][_nonce], "ALREADY_CLAIMED");

        uint256 _n = 5;

        for (uint8 i = 0; i < _n; i++) {
            if (_amounts[i] > 0) {
                if (i == 0) {
                    claimCUBE(
                        _dupNonce,
                        _nonce,
                        _amounts[i],
                        _adminSignatures[i]
                    );
                } else if (i == 1) {
                    claimUSDT(
                        _dupNonce,
                        _nonce,
                        _amounts[i],
                        _adminSignatures[i]
                    );
                } else if (i == 2) {
                    claimMATIC(
                        _dupNonce,
                        _nonce,
                        _amounts[i],
                        _adminSignatures[i]
                    );
                } else if (i == 3) {
                    claimNFTBox(
                        _dupNonce,
                        _nonce,
                        _amounts[i],
                        _adminSignatures[i]
                    );
                }
            }

            if (i == 4 && _attributes.length > 0) {
                claimNFTFragment(
                    _dupNonce,
                    _nonce,
                    _attributes,
                    _adminSignatures[i]
                );
            }
        }

        isClaimed[msg.sender][_nonce] = true;
        emit ClaimedRewards(_nonce, msg.sender);
    }

    function claimRefReward(
        uint256 _dupNonce,
        uint256 _nonce,
        uint256 _amount,
        bytes memory _adminSignature
    ) external nonReentrant {
        if (_dupNonce != 0) {
            require(!isClaimed[msg.sender][_dupNonce], "FORBIDDEN_ACTION");
            isClaimed[msg.sender][_dupNonce] = true;
        }

        require(!isClaimed[msg.sender][_nonce], "ALREADY_CLAIMED");

        require(
            address(this).balance >= _amount,
            "CANNOT_CLAIM_REF_REWARD_NOW"
        );

        address _to = msg.sender;

        bytes32 messageHash = keccak256(
            abi.encodePacked(
                CLAIM_REF_REWARD_SEPARATOR,
                _dupNonce,
                _nonce,
                _to,
                _amount
            )
        );

        require(verifySignature(messageHash, _adminSignature), "NOT_PERMITTED");

        payable(_to).transfer(_amount);

        isClaimed[_to][_nonce] = true;
        emit ClaimedRefReward(_nonce, _to);
    }

    function claimCUBE(
        uint256 _dupNonce,
        uint256 _nonce,
        uint256 _amount,
        bytes memory _adminSignature
    ) internal {
        require(address(usdt) != address(0), "CANNOT_CLAIM_CUBE_NOW");
        address _to = msg.sender;

        bytes32 messageHash = keccak256(
            abi.encodePacked(
                CLAIM_CUBE_SEPARATOR,
                _dupNonce,
                _nonce,
                _to,
                _amount
            )
        );
        require(verifySignature(messageHash, _adminSignature), "NOT_PERMITTED");

        cube.transfer(_to, _amount * 1 ether);
    }

    function claimUSDT(
        uint256 _dupNonce,
        uint256 _nonce,
        uint256 _amount,
        bytes memory _adminSignature
    ) internal {
        require(address(usdt) != address(0), "CANNOT_CLAIM_USDT_NOW");
        address _to = msg.sender;

        bytes32 messageHash = keccak256(
            abi.encodePacked(
                CLAIM_USDT_SEPARATOR,
                _dupNonce,
                _nonce,
                _to,
                _amount
            )
        );

        require(verifySignature(messageHash, _adminSignature), "NOT_PERMITTED");

        usdt.transfer(_to, _amount * 10**6);
    }

    function claimMATIC(
        uint256 _dupNonce,
        uint256 _nonce,
        uint256 _amount,
        bytes memory _adminSignature
    ) internal {
        require(address(this).balance >= _amount, "CANNOT_CLAIM_MATIC_NOW");

        address _to = msg.sender;

        bytes32 messageHash = keccak256(
            abi.encodePacked(
                CLAIM_MATIC_SEPARATOR,
                _dupNonce,
                _nonce,
                _to,
                _amount
            )
        );

        require(verifySignature(messageHash, _adminSignature), "NOT_PERMITTED");

        payable(_to).transfer(_amount * 1 ether);
    }

    function claimNFTFragment(
        uint256 _dupNonce,
        uint256 _nonce,
        uint256[] calldata _attributes,
        bytes memory _adminSignature
    ) internal {
        require(
            address(nftFragment) != address(0),
            "CANNOT_CLAIM_NFT_FRAGMENT_NOW"
        );

        address _to = msg.sender;
        uint256 _amount = _attributes.length;

        bytes32 messageHash = keccak256(
            abi.encodePacked(
                CLAIM_NFT_FRAGMENT_SEPARATOR,
                _dupNonce,
                _nonce,
                _to,
                _attributes
            )
        );

        require(verifySignature(messageHash, _adminSignature), "NOT_PERMITTED");

        nftFragment.safeMintMulti(_to, _amount, _attributes);
    }

    function claimNFTBox(
        uint256 _dupNonce,
        uint256 _nonce,
        uint256 _amount,
        bytes memory _adminSignature
    ) internal {
        require(address(nftBox) != address(0), "CANNOT_CLAIM_NFT_BOX_NOW");

        address _to = msg.sender;

        bytes32 messageHash = keccak256(
            abi.encodePacked(
                CLAIM_NFT_BOX_SEPARATOR,
                _dupNonce,
                _nonce,
                _to,
                _amount
            )
        );
        require(verifySignature(messageHash, _adminSignature), "NOT_PERMITTED");

        nftBox.safeMintMulti(_to, _amount);
    }

    function verifySignature(bytes32 _messageHash, bytes memory _adminSignature)
        public
        view
        returns (bool)
    {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(_messageHash);

        // whether this permission is granted from admin
        // whether this user is the user admin permits to claim
        bool isPermittedByAdmin = recoverSigner(
            ethSignedMessageHash,
            _adminSignature
        ) == adminSigner;

        return isPermittedByAdmin;
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(bytes32 _messageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_messageHash, v, r, s);
    }

    function splitSignature(bytes memory _sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(_sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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