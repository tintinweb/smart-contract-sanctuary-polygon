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