import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interface/IUpbondFaucetERC20.sol";
import "./interface/IUpbondFaucetERC721.sol";
import "./interface/IUpbondFaucetERC1155.sol";
import "./faucet_wrapper.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract upbondFaucetFactory is Ownable, ReentrancyGuard{
    using Address for address;

    address public immutable wrapper;
    address public immutable walletProof;
    
    address public trustedForwarder;

    address private implementFaucetERC20;
    address private implementFaucetERC721;
    address private implementFaucetERC1155;

    mapping (address => address) private faucetERC20;
    mapping (address => address) private faucetERC721;
    mapping (address => address) private faucetERC1155;

    event createdERC20Faucet(
        address indexed token,
        address indexed faucet
    );
    event createdERC721Faucet(
        address indexed token,
        address indexed faucet
    );
    event createdERC1155Faucet(
        address indexed token,
        address indexed faucet
    );
    event updatedTrustForwarder(
        address indexed oldForwarder,
        address indexed newForwarder
    );

    struct wrapperArgument{
        bool useKyc;
        bool onceClaim;
        uint256 claimReward;
        uint256 delayClaim;
    }

    constructor(
        address proofWallet,
        address valueWrapper,
        address[3] memory implementations,
        wrapperArgument memory wrapperFaucetArg
    ){
        require(
            implementations.length == 3,
            "upbondFaucetFactory : Please fill all implementation address"
        );

        for (uint a; a < implementations.length; a++) {
            require(
                implementations[a].isContract(),
                "upbondFaucetFactory : Please fill with correct implementation address"
            );
        }

        walletProof = proofWallet;
        wrapper = valueWrapper;

        address proof;

        if(wrapperFaucetArg.useKyc == true){
            proof = proofWallet;
        }

        implementFaucetERC20 = implementations[0];
        implementFaucetERC721 = implementations[1];
        implementFaucetERC1155 = implementations[2];

        address wrapperFaucet = address(
            new upbondFaucetWrapper(
                wrapperFaucetArg.onceClaim,
                wrapperFaucetArg.claimReward,
                wrapperFaucetArg.delayClaim,
                valueWrapper,
                proof
            )
        );
        faucetERC20[wrapper] = wrapperFaucet;

        emit createdERC20Faucet(
            wrapper,
            wrapperFaucet
        );
    }

    function getFaucetERC20Address(
        address token
    ) public virtual view returns(address) {
        require(
            faucetERC20[token] != address(0),
            "upbondFaucetFactory : Faucet not deployed"
        );

        return faucetERC20[token];
    }

    function getFaucetERC721Address(
        address token
    ) public virtual view returns(address) {
        require(
            faucetERC721[token] != address(0),
            "upbondFaucetFactory : Faucet not deployed"
        );

        return faucetERC721[token];
    }

    function getFaucetERC1155Address(
        address token
    ) public virtual view returns(address) {
        require(
            faucetERC1155[token] != address(0),
            "upbondFaucetFactory : Faucet not deployed"
        );

        return faucetERC1155[token];
    }

    function createERC20Faucet(
        bool useKyc,
        bool onceClaim,
        uint256 claimReward,
        uint256 delayClaim,
        address token
    ) external virtual onlyOwner nonReentrant {
        require(
            token != wrapper,
            "upbondFaucetFactory : Wrapper faucet already deployed"
        );
        require(
            IERC20Metadata(token).decimals() > 0,
            "upbondFaucetFactory : This address is not ERC20"
        );
        require(
            faucetERC20[token] == address(0),
            "upbondFaucetFactory : This faucet for this token already created"
        );

        address proof;

        if(useKyc == true){
            proof = walletProof;
        }

        bytes32 salt = keccak256(abi.encodePacked(token, address(this)));
        address faucetERC20Address = Clones.cloneDeterministic(
            implementFaucetERC20,
            salt
        );
        
        IUpbondFaucetERC20(faucetERC20Address)._initialize(onceClaim, claimReward, delayClaim, token, proof);

        faucetERC20[token] = faucetERC20Address;

        emit createdERC20Faucet(
            token,
            faucetERC20Address
        );
    }

    function createERC721Faucet(
        bool useKyc,
        bool onceClaim,
        uint256 delayClaim,
        address token
    ) external virtual onlyOwner nonReentrant {
        require(
            IERC165(token).supportsInterface(type(IERC721).interfaceId),
            "upbondFaucetFactory : This token not support OpenZeppelin ERC721 standart"
        );
        require(
            faucetERC721[token] == address(0),
            "upbondFaucetFactory : This faucet for this token already created"
        );

        bytes32 salt = keccak256(abi.encodePacked(token, address(this)));
        address faucetERC721Address = Clones.cloneDeterministic(
            implementFaucetERC721,
            salt
        );

        address proof;

        if(useKyc == true){
            proof = walletProof;
        }
        
        IUpbondFaucetERC721(faucetERC721Address)._initialize(onceClaim, delayClaim, token, proof);

        faucetERC721[token] = faucetERC721Address;

        emit createdERC721Faucet(
            token,
            faucetERC721Address
        );
    }

    function createERC1155Faucet(
        bool useKyc,
        bool onceClaim,
        uint256 delayClaim,
        address token
    ) external virtual onlyOwner nonReentrant {
        require(
            IERC165(token).supportsInterface(type(IERC1155).interfaceId),
            "upbondFaucetFactory : This token not support OpenZeppelin ERC1155 standart"
        );
        require(
            faucetERC1155[token] == address(0),
            "upbondFaucetFactory : This faucet for this token already created"
        );

        bytes32 salt = keccak256(abi.encodePacked(token, address(this)));
        address faucetERC1155Address = Clones.cloneDeterministic(
            implementFaucetERC1155,
            salt
        );

        address proof;

        if(useKyc == true){
            proof = walletProof;
        }
        
        IUpbondFaucetERC1155(faucetERC1155Address)._initialize(onceClaim, delayClaim, token, proof);

        faucetERC1155[token] = faucetERC1155Address;

        emit createdERC1155Faucet(
            token,
            faucetERC1155Address
        );
    }

    function updateTrustForwarder(
        address newForwarder
    ) external virtual onlyOwner nonReentrant {
        address oldForwarder =  trustedForwarder;
        trustedForwarder = newForwarder;

        emit updatedTrustForwarder(
            oldForwarder,
            newForwarder
        );
    }
}

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./abstract/upbondFactoryController.sol";
import "./interface/IUpbondWalletProof.sol";
import "./interface/IWrapper.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract upbondFaucetWrapper is upbondFactoryController, ReentrancyGuard{
    address private walletProof;
    
    address public wrapper;
    faucetRoles public faucetConfig;

    mapping (address => bool) private claimed;
    mapping (address => uint256) private eligibleNextClaim;

    event claimedFaucet(
        address indexed claimer,
        uint256 faucetAmount
    );

    struct faucetRoles{
        uint256 delay;
        uint256 reward;
        bool claimOnce;
    }

    constructor(
        bool onceClaim,
        uint256 claimReward,
        uint256 delayClaim,
        address wrap,
        address kyc
    ){
        if(onceClaim == true){
            require(
                delayClaim == 0,
                "upbondFaucet : Please set delay claim to zero if onceClaim is `true`"
            );
        }else{
            require(
                delayClaim > 0,
                "upbondFaucet : Please set delay claim to more than zero if onceClaim is `false`"
            );
        }

        require(
            claimReward > 0,
            "upbondFaucet : Please set reward more than zero"
        );

        if(kyc != address(0)){
            walletProof = kyc;
        }

        factory = _msgSender();
        wrapper = wrap;
        faucetConfig = faucetRoles(
            delayClaim,
            claimReward,
            onceClaim
        );
    }

    receive() external payable {
        if(_msgSender() != wrapper && msg.value > 0){
            IWrapper(wrapper).deposit{value: msg.value }();
        }
    }

    function alreadyClaimed(
        address claimer
    ) public virtual view returns(bool) {
        require(
            faucetConfig.claimOnce == true,
            "upbondFaucet : This action not needed!"
        );

        return claimed[claimer];
    }

    function claimerDelay(
        address claimer
    ) public virtual view returns(uint256){
        require(
            faucetConfig.claimOnce == false,
            "upbondFaucet : This action not needed!"
        );

        return eligibleNextClaim[claimer];
    }

    function isUseKyc() public virtual view returns(bool){
        return walletProof != address(0);
    }

    function claimFaucet(
        bytes32 claimHash
    ) external virtual nonReentrant {
        if(isUseKyc() == true){
            string memory proofData = IUpbondWalletProof(walletProof).getProofData(_msgSender());
            bytes32 hash = keccak256(abi.encodePacked(address(this),_msgSender(),proofData));
            
            require(
                claimHash == hash,
                "upbondFaucet : Invalid claimhash"
            );
        }else{
            bytes32 hash = keccak256(abi.encodePacked(address(this),_msgSender()));

            require(
                claimHash == hash,
                "upbondFaucet : Invalid claimhash"
            );
        }

        if(faucetConfig.claimOnce == true){
            require(
                alreadyClaimed(_msgSender()) == false,
                "upbondFaucet : You already claimed!"
            );

            claimed[_msgSender()] = true;
        }else{
            require(
                claimerDelay(_msgSender()) < block.timestamp,
                "upbondFaucet : Please wait until eligibled time elapsed!"
            );

            eligibleNextClaim[_msgSender()] = block.timestamp + faucetConfig.delay;
        }

        require(
            IWrapper(wrapper).balanceOf(address(this)) >= faucetConfig.reward,
            "upbondFaucet : Reward is out of stock"
        );

        IWrapper(wrapper).withdraw(faucetConfig.reward);
        safeValueTransfer(
            _msgSender(),
            faucetConfig.reward
        );

        emit claimedFaucet(
            _msgSender(),
            faucetConfig.reward
        );
    }

    function emergencyWithdrawFaucet() external virtual onlyFactoryOwner nonReentrant {
        uint256 allBalance = IWrapper(wrapper).balanceOf(address(this));

        IWrapper(wrapper).withdraw(allBalance);
        safeValueTransfer(
            _msgSender(),
            allBalance
        );
    }

    function editFaucetRoles(
        bool onceClaim,
        uint256 claimReward,
        uint256 delayClaim
    ) external virtual onlyFactoryOwner nonReentrant {
        if(onceClaim == true){
            require(
                delayClaim == 0,
                "upbondFaucet : Please set delay claim to zero if onceClaim is `true`"
            );
        }else{
            require(
                delayClaim > 0,
                "upbondFaucet : Please set delay claim to more than zero if onceClaim is `false`"
            );
        }

        require(
            claimReward > 0,
            "upbondFaucet : Please set reward more than zero"
        );

        faucetConfig = faucetRoles(
            delayClaim,
            claimReward,
            onceClaim
        );
    }

    function useKyc(
        bool status
    ) external virtual onlyFactoryOwner nonReentrant {
        if(status == true){
            walletProof = IUpbondFaucetFactory(factory).walletProof();
        }else{
            walletProof = address(0);
        }
    }

    function safeValueTransfer(
        address to,
        uint value
    ) private {
        (bool success,) = payable(to).call{value:value}("");
        require(
            success,
            "Transfer failed"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IUpbondFaucetERC20 {
  function _initialize ( bool onceClaim, uint256 claimReward, uint256 delayClaim, address faucet, address proof ) external;
  function alreadyClaimed ( address claimer ) external view returns ( bool );
  function claimFaucet ( bytes32 claimHash ) external;
  function claimerDelay ( address claimer ) external view returns ( uint256 );
  function editFaucetRoles ( bool onceClaim, uint256 claimReward, uint256 delayClaim ) external;
  function emergencyWithdrawFaucet (  ) external;
  function factory (  ) external view returns ( address );
  function faucetConfig (  ) external view returns ( uint256 delay, uint256 reward, bool claimOnce );
  function faucetToken (  ) external view returns ( address );
  function isTrustedForwarder ( address forwarder ) external view returns ( bool );
  function isUseKyc (  ) external view returns ( bool );
  function useKyc ( bool status ) external;
  function wrapper (  ) external view returns ( address );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IUpbondFaucetERC1155{
  function _initialize ( bool onceClaim, uint256 delayClaim, address faucet, address proof ) external;
  function alreadyClaimed ( address claimer ) external view returns ( bool );
  function claimFaucet ( bytes32 claimHash ) external;
  function claimerDelay ( address claimer ) external view returns ( uint256 );
  function editFaucetRoles ( bool onceClaim, uint256 delayClaim ) external;
  function emergencyWithdrawFaucet (  ) external;
  function emergencyWithdrawUnregisteredFaucet ( uint256[] memory tokenIds ) external;
  function factory (  ) external view returns ( address );
  function faucetConfig (  ) external view returns ( bool claimOnce, uint256 delay );
  function faucetToken (  ) external view returns ( address );
  function isTrustedForwarder ( address forwarder ) external view returns ( bool );
  function isUseKyc (  ) external view returns ( bool );
  function onERC1155BatchReceived ( address, address, uint256[] memory, uint256[] memory, bytes memory ) external returns ( bytes4 );
  function onERC1155Received ( address, address, uint256, uint256, bytes memory ) external returns ( bytes4 );
  function registeringReward ( uint256[] memory tokenIds ) external;
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
  function useKyc ( bool status ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IUpbondFaucetERC721 {
  function _initialize ( bool onceClaim, uint256 delayClaim, address faucet, address proof ) external;
  function alreadyClaimed ( address claimer ) external view returns ( bool );
  function claimFaucet ( bytes32 claimHash ) external;
  function claimerDelay ( address claimer ) external view returns ( uint256 );
  function editFaucetRoles ( bool onceClaim, uint256 delayClaim ) external;
  function emergencyWithdrawFaucet (  ) external;
  function emergencyWithdrawUnregisteredFaucet ( uint256[] memory tokenIds ) external;
  function factory (  ) external view returns ( address );
  function faucetConfig (  ) external view returns ( bool claimOnce, uint256 delay );
  function faucetToken (  ) external view returns ( address );
  function isTrustedForwarder ( address forwarder ) external view returns ( bool );
  function isUseKyc (  ) external view returns ( bool );
  function onERC721Received ( address, address, uint256, bytes memory ) external returns ( bytes4 );
  function registeringReward ( uint256[] memory tokenIds ) external;
  function useKyc ( bool status ) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IUpbondWalletProof {
  function getProofData (address wallet) external view returns (string memory);
  function moveProveData (address oldWallet, address newWallet) external;
  function owner () external view returns (address);
  function renounceOwnership () external;
  function setAdmin( address wallet, bool status ) external;
  function setProofData (address wallet, string memory proof) external;
  function transferOwnership (address newOwner) external;
  function isAdmin(address wallet) external view returns(bool);
}

import "@openzeppelin/contracts/utils/Context.sol";
import "../interface/IUpbondFaucetFactory.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

abstract contract upbondFactoryController is Context {
    address public factory;

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == IUpbondFaucetFactory(factory).trustedForwarder();
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (factory != address(0) && isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (factory != address(0) && isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    modifier onlyFactoryOwner(){
        require(
            _checkIsOwner(_msgSender()) == true,
            "upbondFactoryController : You are not factory"
        );
        _;
    }

    function _checkIsOwner(
        address user
    ) internal view returns(bool){
        return user == IUpbondFaucetFactory(factory).owner();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IWrapper{
    function totalSupply() external view returns (uint);
    
    function balanceOf(
        address account
    ) external view returns (uint256);
    
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
    
    function deposit() external payable;
    
    function withdraw(
        uint256 amount
    ) external;

    function approve(
        address spender,
        uint256 amount
    ) external;
    
    function transfer(
        address destination,
        uint256 amount
    ) external;
    
    function transferFrom(
        address owner,
        address destination,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IUpbondFaucetFactory {
  function createERC1155Faucet ( bool useKyc, bool onceClaim, uint256 delayClaim, address token ) external;
  function createERC20Faucet ( bool useKyc, bool onceClaim, uint256 claimReward, uint256 delayClaim, address token ) external;
  function createERC721Faucet ( bool useKyc, bool onceClaim, uint256 delayClaim, address token ) external;
  function getFaucetERC1155Address ( address token ) external view returns ( address );
  function getFaucetERC20Address ( address token ) external view returns ( address );
  function getFaucetERC721Address ( address token ) external view returns ( address );
  function owner (  ) external view returns ( address );
  function renounceOwnership (  ) external;
  function transferOwnership ( address newOwner ) external;
  function trustedForwarder (  ) external view returns ( address );
  function updateERC1155FaucetImplementation ( address newImplement ) external;
  function updateERC20FaucetImplementation ( address newImplement ) external;
  function updateERC721FaucetImplementation ( address newImplement ) external;
  function updateTrustForwarder ( address newForwarder ) external;
  function walletProof (  ) external view returns ( address );
  function wrapper (  ) external view returns ( address );
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