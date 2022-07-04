// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { OwnableInternal } from "@solidstate/contracts/access/ownable/OwnableInternal.sol";

import { IERC20ServiceFacet } from "../../interfaces/IERC20ServiceFacet.sol";
import { ERC20Service } from "./ERC20Service.sol";
import { ERC20ServiceStorage } from "./ERC20ServiceStorage.sol";


/**
 * @title ERC20ServiceFacet 
 */
contract ERC20ServiceFacet is IERC20ServiceFacet, ERC20Service, OwnableInternal {
    using ERC20ServiceStorage for ERC20ServiceStorage.Layout;

    /**
     * @inheritdoc IERC20ServiceFacet
     */
    function erc20ServiceFacetVersion() external pure override returns (string memory) {
        return "0.1.0.alpha";
    }

    function _beforeTransferERC20(address token, address to, uint256 amount) 
        internal
        virtual 
        view 
        override 
        onlyOwner
    {
        super._beforeTransferERC20(token, to, amount);
    }

    function _beforeTransferERC20From(address token, address from, address to, uint256 amount) 
        internal 
        virtual 
        view 
        override 
        onlyOwner
    {
        super._beforeTransferERC20From(token, from, to, amount);
    }

    function _beforeApproveERC20(address token, address spender, uint256 amount) 
        internal 
        virtual 
        view 
        override 
        onlyOwner 
    {
        super._beforeApproveERC20(token, spender, amount);
    }

    function _beforeRegisterERC20(address tokenAddress) internal virtual view override onlyOwner {
        super._beforeRegisterERC20(tokenAddress);
    }

    function _beforeRemoveERC20(address tokenAddress) internal virtual view override onlyOwner {
        super._beforeRemoveERC20(tokenAddress);
    }

    function _beforedepositERC20(address tokenAddress, uint256 amount)
        internal
        virtual
        view 
        override
        onlyOwner
    {
        super._beforedepositERC20(tokenAddress, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnableInternal } from './IOwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal is IOwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(
            msg.sender == OwnableStorage.layout().owner,
            'Ownable: sender must be owner'
        );
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transferOwnership(address account) internal virtual {
        OwnableStorage.layout().setOwner(account);
        emit OwnershipTransferred(msg.sender, account);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { IERC20Service } from "../token/ERC20/IERC20Service.sol";


/**
 * @title ERC20ServiceFacet interface
 */
interface IERC20ServiceFacet is IERC20Service {
    /**
     * @notice return the current version of ERC20ServiceFacet
     */
    function erc20ServiceFacetVersion() external pure returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IERC20Service } from "./IERC20Service.sol";
import { ERC20ServiceInternal } from "./ERC20ServiceInternal.sol";
import { ERC20ServiceStorage } from "./ERC20ServiceStorage.sol";

/**
 * @title ERC20Service 
 */
abstract contract ERC20Service is
    IERC20Service,
    ERC20ServiceInternal
{
    using ERC20ServiceStorage for ERC20ServiceStorage.Layout;

    /**
     * @inheritdoc IERC20Service
     */
    function transferERC20(
        address token,
        address to,
        uint256 amount
    ) external override returns (bool) {
        _beforeTransferERC20(token, to, amount);

        return IERC20(token).transfer(to, amount);
    }

    /**
     * @inheritdoc IERC20Service
     */
    function transferERC20From(
        address token,
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        _beforeTransferERC20From(token, from, to, amount);

        return IERC20(token).transferFrom(from, to, amount);
    }

    /**
     * @inheritdoc IERC20Service
     */
    function approveERC20(
        address token,
        address spender,
        uint256 amount
    ) external override returns (bool) {
        _beforeApproveERC20(token, spender, amount);

        return IERC20(token).approve(spender, amount);
    }

    /**
     * @inheritdoc IERC20Service
     */
    function registerERC20(address token) external override {
        _beforeRegisterERC20(token);

        _registerERC20(token);

        _afterRegisterERC20(token);
    }

    /**
     * @inheritdoc IERC20Service
     */
    function removeERC20(address token) external override {
        _beforeRemoveERC20(token);

        _removeERC20(token);

        _afterRemoveERC20(token);
    }

    /**
     * @inheritdoc IERC20Service
     */
    function depositERC20(address token, uint256 amount) external override {
        _beforedepositERC20(token, amount);

        _depositERC20(token, amount);
        require(IERC20(token).transferFrom(msg.sender, address(this), amount));

        emit ERC20Deposited(token, amount);

        _afterDepositERC20(token, amount);
    }

    /**
     * @inheritdoc IERC20Service
     */
    function getAllTrackedERC20Tokens() external view override returns (address[] memory) {
        return _getAllTrackedERC20Tokens();
    }

    /**
     * @inheritdoc IERC20Service
     */
    function balanceOfERC20(address token) external view override returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

/**
 * @title ERC20Service Storage base on Diamond Standard Layout storage pattern
 */
library ERC20ServiceStorage {
    struct Layout {
        mapping(address => uint256) erc20TokenIndex;
        address[] erc20Tokens;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("simplicy.contracts.storage.ERC20Service");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /**
     * @notice add an ERC20 token to the storage
     * @param tokenAddress: the address of the ERC20 token
     */
    function storeERC20(Layout storage s, address tokenAddress)
        internal {
            uint256 arrayIndex = s.erc20Tokens.length;
            uint256 index = arrayIndex + 1;
            s.erc20Tokens.push(tokenAddress);
            s.erc20TokenIndex[tokenAddress] = index;
    }

    /**
     * @notice delete an ERC20 token from the storage,
     * we are going to switch the last item in the array with the one we are replacing.
     * That way when we pop, we are removing the correct item. 
     *
     * There are two cases we need to handle:
     *  - the address we are removing is not the last address in the array
     *  - or it is the last address in the array. 
     * @param tokenAddress: the address of the ERC20 token
     */
    function deleteERC20(Layout storage s, address tokenAddress)
        internal {
            uint256 index = s.erc20TokenIndex[tokenAddress];
            uint256 arrayIndex = index - 1;
            require(arrayIndex >= 0, "ERC20_NOT_EXISTS");
            if(arrayIndex != s.erc20Tokens.length - 1) {
                 s.erc20Tokens[arrayIndex] = s.erc20Tokens[s.erc20Tokens.length - 1];
                 s.erc20TokenIndex[s.erc20Tokens[arrayIndex]] = index;
            }
            s.erc20Tokens.pop();
            delete s.erc20TokenIndex[tokenAddress];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC173Internal } from '../IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC173 interface needed by internal functions
 */
interface IERC173Internal {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import {IERC20ServiceInternal} from "./IERC20ServiceInternal.sol";

/**
 * @title ERC20Service interface 
 */
interface IERC20Service is IERC20ServiceInternal {
    /**
     * @notice sets `amount` as the allowance of `spender` over the caller's tokens.
     * @param token: the address of tracked token to move.
     * @param spender: the address of the spender.
     * @param amount: the amount of tokens to set as allowance.
     * @return returns a boolean value indicating whether the operation succeeded.
     */
    function approveERC20(address token, address spender, uint256 amount) external returns (bool);

    /**
     * @notice moves `amount` tracked tokens from the caller's account to `to`.
     * @param token: the address of tracked token to move.
     * @param to: the address of the recipient.
     * @param amount: the amount of tokens to move.
     * @return returns a boolean value indicating whether the operation succeeded.
     */
    function transferERC20(address token, address to, uint256 amount) external returns (bool);

    /**
     * @notice transfer tokens to given recipient on behalf of given holder.
     * @param token: the address of tracked token to move.
     * @param from: holder of tokens prior to transfer.
     * @param to: beneficiary of token transfer.
     * @param amount quantity of tokens to transfer.
     * @return success status (always true; otherwise function should revert).
     */
    function transferERC20From(
        address token,
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice register a new ERC20 token.
     * @param token: the address of the ERC721 token.
     */
    function registerERC20(address token) external;

    /**
     * @notice remove a new ERC20 token from ERC20Service.
     * @param token: the address of the ERC20 token.
     */
    function removeERC20(address token) external;

    /**
     * @notice deposit a ERC20 token to ERC20Service.
     * @param token: the address of the ERC20 token.
     * @param amount: the amount of token to deposit.
     */
    function depositERC20(address token, uint256 amount) external;

     /**
     * @notice query all tracked ERC20 tokens.
     * @return tracked ERC20 tokens.
     */
    function getAllTrackedERC20Tokens() external view returns (address[] memory);

    /**
     * @notice query the token balance of the given token for this address.
     * @param token : the address of the token.
     * @return token balance of this address.
     */
    function balanceOfERC20(address token) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

/**
 * @title Partial ERC20Service interface needed by internal functions
 */
interface IERC20ServiceInternal {
    /**
     * @notice emitted when a new ERC20 token is registered
     * @param tokenAddress: the address of the ERC20 token
     */
    event ERC20TokenTracked(address indexed tokenAddress);

    /**
     * @notice emitted when a new ERC20 token is removed
     * @param tokenAddress: the address of the ERC20 token
     */
    event ERC20TokenRemoved(address tokenAddress); 

    /**
     * @notice emitted when a ERC20 token is deposited.
     * @param tokenAddress: the address of the ERC20 token.
     * @param amount: the amount of token deposited.
     */
    event ERC20Deposited(address indexed tokenAddress, uint256 amount);
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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { IERC20ServiceInternal } from "./IERC20ServiceInternal.sol";
import {ERC20ServiceStorage} from "./ERC20ServiceStorage.sol";

/**
 * @title ERC20Service internal functions, excluding optional extensions
 */
abstract contract ERC20ServiceInternal is IERC20ServiceInternal {
    using ERC20ServiceStorage for ERC20ServiceStorage.Layout;

    modifier erc20IsTracked(address tokenAddress) {
        require(_getERC20TokenIndex(tokenAddress) > 0, "ERC20Service: token not tracked");
        _;
    }

    /**
     * @notice register a new ERC20 token
     * @param tokenAddress: the address of the ERC721 token
     */
    function _registerERC20(address tokenAddress) internal virtual {
        ERC20ServiceStorage.layout().storeERC20(tokenAddress);

        emit ERC20TokenTracked(tokenAddress);
    }

    /**
     * @notice internal remove a new ERC20 token from ERC20Service
     * @param tokenAddress: the address of the ERC20 token
     */
    function _removeERC20(address tokenAddress) internal virtual {
        ERC20ServiceStorage.layout().deleteERC20(tokenAddress);

        emit ERC20TokenRemoved(tokenAddress);
    }

    /**
     * @notice internal function: deposit a ERC20 token to ERC20Service.
     * @param token: the address of the ERC20 token.
     * @param amount: the amount of tokens to deposit.
     */
    function _depositERC20(address token, uint256 amount) internal virtual {
        if (_getERC20TokenIndex(token) == 0) {
            _registerERC20(token);
        }
    }

    /**
     * @notice query the mapping index of ERC20 tokens
     */
    function _getERC20TokenIndex(address tokenAddress) internal view returns (uint256) {
        return ERC20ServiceStorage.layout().erc20TokenIndex[tokenAddress];
    }

    /**
     * @notice query all tracked ERC20 tokens
     */
    function _getAllTrackedERC20Tokens() internal view returns (address[] memory) {
        return ERC20ServiceStorage.layout().erc20Tokens;
    }

    /**
     * @notice hook that is called before transferERC20
     */
    function _beforeTransferERC20(address token, address to, uint256 amount) internal virtual view erc20IsTracked(token) {}

    /**
     * @notice hook that is called before transferERC20From
     */
    function _beforeTransferERC20From(address token, address from, address to, uint256 amount) internal virtual view erc20IsTracked(token) {}


    /**
     * @notice hook that is called before approveERC20
     */
    function _beforeApproveERC20(address token, address spender, uint256 amount) internal virtual view erc20IsTracked(token) {}

    /**
     * @notice hook that is called before registerERC20Token
     */
    function _beforeRegisterERC20(address tokenAddress) internal virtual view {
        require(tokenAddress != address(0), "ERC20Service: tokenAddress is the zero address");
        require(_getERC20TokenIndex(tokenAddress) == 0, "ERC20Service: ERC20 token is already tracked");
    }

    /**
     * @notice hook that is called after registerERC20Token
     */
    function _afterRegisterERC20(address tokenAddress) internal virtual view {}

    /**
     * @notice hook that is called before removeERC20Token
     */
    function _beforeRemoveERC20(address tokenAddress) internal virtual view erc20IsTracked(tokenAddress) {
        require(tokenAddress != address(0), "ERC20Service: tokenAddress is the zero address");
    }

    /**
     * @notice hook that is called after removeERC20Token
     */
    function _afterRemoveERC20(address tokenAddress) internal virtual view {}

    /**
     * @notice hook that is called before depositERC20
     */
    function _beforedepositERC20(address tokenAddress, uint256 amount) internal virtual view {
        require(tokenAddress != address(0), "ERC20Service: tokenAddress is the zero address");
        require(amount > 0, "ERC20Service: amount is zero");
    }

    /**
     * @notice hook that is called after depositERC20
     */
    function _afterDepositERC20(address tokenAddress, uint256 amount) internal virtual view {}
}