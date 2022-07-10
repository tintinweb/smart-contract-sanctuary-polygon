// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { SafeOwnableInternal } from "@solidstate/contracts/access/ownable/SafeOwnableInternal.sol";
import { IEtherServiceFacet } from "../interfaces/IEtherServiceFacet.sol";

/**
 * @title EtherServiceFacet 
 */
contract EtherServiceFacet is  IEtherServiceFacet, SafeOwnableInternal {   

    /**
     * @notice emitted when a ether is transfer
     * @param to: receiver of the ether
     * @param amount: the amount ether transferred
     */
    event EtherTransfered(address payable to,uint256 amount);  

    /**
     * @inheritdoc IEtherServiceFacet
     */
    function transferEther(
        address payable to,
        uint amount
    ) external override onlyOwner returns (bool){
        require(to != address(0), "EtherServiceFacet: to adress is the zero address");
        require(amount > 0, "EtherServiceFacet: amount is zero");

        to.transfer(amount);

        emit EtherTransfered(to, amount);
        return true;
    }

    /**
     * @inheritdoc IEtherServiceFacet
     */
    function etherServiceFacetVersion() external pure override returns (string memory) {
        return "0.1.0.alpha";
    }

    /**
     * @inheritdoc IEtherServiceFacet
     */
    function getEtherBalance() external view returns (uint) {
        return address(this).balance;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ISafeOwnableInternal } from './ISafeOwnableInternal.sol';
import { OwnableInternal } from './OwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';
import { SafeOwnableStorage } from './SafeOwnableStorage.sol';

abstract contract SafeOwnableInternal is ISafeOwnableInternal, OwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;
    using SafeOwnableStorage for SafeOwnableStorage.Layout;

    modifier onlyNomineeOwner() {
        require(
            msg.sender == _nomineeOwner(),
            'SafeOwnable: sender must be nominee owner'
        );
        _;
    }

    /**
     * @notice get the nominated owner who has permission to call acceptOwnership
     */
    function _nomineeOwner() internal view virtual returns (address) {
        return SafeOwnableStorage.layout().nomineeOwner;
    }

    /**
     * @notice accept transfer of contract ownership
     */
    function _acceptOwnership() internal virtual {
        OwnableStorage.Layout storage l = OwnableStorage.layout();
        emit OwnershipTransferred(l.owner, msg.sender);
        l.setOwner(msg.sender);
        SafeOwnableStorage.layout().setNomineeOwner(address(0));
    }

    /**
     * @notice set nominee owner, granting permission to call acceptOwnership
     */
    function _transferOwnership(address account) internal virtual override {
        SafeOwnableStorage.layout().setNomineeOwner(account);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;


/**
 * @title RecoveryFacet interface
 */
interface IEtherServiceFacet {
    /**
     * @notice moves `amount` of ether from the caller's account to `to`.
     * @param to: the payable address of the recipient.
     * @param amount: the amount of tokens to move.
     * @return returns a boolean value indicating whether the operation succeeded.
     */
    function transferEther(address payable to, uint amount) external returns (bool);

    /**
     * @notice return the current version of RecoveryFacet
     */
    function etherServiceFacetVersion() external pure returns (string memory);

    /**
     * @notice return the current balance of this contract
     */
    function getEtherBalance() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnableInternal } from './IOwnableInternal.sol';

interface ISafeOwnableInternal is IOwnableInternal {}

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

library SafeOwnableStorage {
    struct Layout {
        address nomineeOwner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.SafeOwnable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setNomineeOwner(Layout storage l, address nomineeOwner) internal {
        l.nomineeOwner = nomineeOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC173Internal } from '../IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {}

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