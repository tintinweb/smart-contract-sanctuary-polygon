// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

pragma solidity 0.8.0;

import "./utils/SafeMath.sol";
import "./utils/Ownable.sol";

/**
 * @title The base contract that contains the base logic, structs and data that are needed
 * @author Adam Southey
 */
contract KittyBase is Ownable {
    using SafeMath for uint256;

    event Birth(
        address owner,
        uint256 kittyId,
        uint256 momId,
        uint256 dadId,
        uint256 genes
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed kittyId
    );

    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _kittyId
    );

    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    struct Kitty {
        // The unique genes of this kitty
        uint256 genes;
        // The timestamp from the block when the kitty was born
        uint64 birthTime;
        // The references to its parents, set to 0 for gen0 cats
        uint32 momId;
        uint32 dadId;
        // The genereation of the kitty. Kitties start with gen0,
        // and each breeded generation will have a higher generation number
        uint16 generation;
    }

    /**
     * @dev An array containing all kitties
     */
    Kitty[] internal _kitties;

    /// @dev Mapping from kitty id to owner address, must be a valid non-0 address
    mapping(uint256 => address) internal _kittyIdToOwner;
    /// @dev Mapping from kitty id to approved address
    mapping(uint256 => address) internal _kittyIdToApproved;
    /// @dev Mapping from owner to number of owned kitty
    mapping(address => uint256) internal _ownedKittiesCount;
    /// @dev Mapping from kitty id to number of children
    mapping(uint256 => uint256[]) internal _kittyToChildren;

    /// @dev Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    /**
     * @dev Assign ownership of a specific Kitty to an address.
     * @dev This poses no restriction on msg.sender
     * @param _from The address from who to transfer from, can be 0 for creation of a kitty
     * @param _to The address to who to transfer to, cannot be 0 address
     * @param _kittyId The id of the transfering kitty,
     */
    function _transfer(
        address _from,
        address _to,
        uint256 _kittyId
    ) internal {
        require(_to != address(0), "transfer to the zero address");
        require(_to != address(this));

        _ownedKittiesCount[_to] = _ownedKittiesCount[_to].add(1);
        _kittyIdToOwner[_kittyId] = _to;

        if (_from != address(0)) {
            _ownedKittiesCount[_from] = _ownedKittiesCount[_from].sub(1);
            delete _kittyIdToApproved[_kittyId];
        }

        emit Transfer(_from, _to, _kittyId);
    }

    /**
     * @dev Logic for creation of a kitty, via gen0 creation or breeding.
     * @param _momId The mother of the kitty (0 for gen0)
     * @param _dadId The dad of the kitty (0 for gen0)
     * @param _generation The generation number of this cat, must be computed by caller
     * @param _genes The generic code, must me computed by the caller
     * @param _owner The initial owner, must me non-zero
     * @return The id of the created kitty
     */
    function _createKitty(
        uint256 _momId,
        uint256 _dadId,
        uint256 _generation,
        uint256 _genes,
        address _owner
    ) internal returns (uint256) {
        Kitty memory _kitty = Kitty({
            genes: _genes,
            birthTime: uint64(block.timestamp),
            momId: uint32(_momId),
            dadId: uint32(_dadId),
            generation: uint16(_generation)
        });

        _kitties.push(_kitty);
        uint256 newKittyId = _kitties.length -1;

        emit Birth(_owner, newKittyId, _momId, _dadId, _genes);

        _transfer(address(0), _owner, newKittyId);

        return newKittyId;
    }
}

pragma solidity 0.8.0;

import "./KittyOwnership.sol";
import "./utils/SafeMath.sol";
/**
 * @title The KittyBreeding contract.
 * @author Adam Southey
 */
contract KittyBreeding is KittyOwnership {

  using SafeMath for uint256;
    /**
     * @dev Returns a binary between 00000000-11111111
     */
    function _getRandom() internal view returns (uint8) {
        return uint8(block.timestamp % 255);
    }

    /**
     * @dev calculates the max of 2 numbers
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev mix new dna from 2 input dnas
     */
    function _mixDna(uint256 _dna1, uint256 _dna2) internal view returns (uint256) {
      uint256[8] memory _geneArray;
      uint8 _random = _getRandom();
      uint8 index = 7;

      // Bitshift: move to next binary bit
      for (uint256 i = 1; i <= 128; i = i * 2) {
        // Binary mask with random number
        // Then add 2 last digits from the dna to the new dna
        if (_random & i != 0) {
            _geneArray[index] = uint8(_dna1 % 100);
        } else {
            _geneArray[index] = uint8(_dna2 % 100);
        }

        _dna1 = _dna1 / 100;
        _dna2 = _dna2 / 100;
        index = index - 1;
      }

      // Add a random parameter in a random place
      uint8 newGeneIndex = _random % 7;
      _geneArray[newGeneIndex] = _random % 99;

      uint256 newGene;

      for (uint256 i = 0; i < 8; i = i + 1) {
        newGene = newGene.add(_geneArray[i]);

        if (i != 7) {
          newGene = newGene.mul(100);
        }
      }

      return newGene;
    }

    /**
     * @notice Breed a new kitty based on a mom and dad
     * @param _momId the id of the mom
     * @param _dadId the id of the dad
     */
    function breed(uint256 _momId, uint256 _dadId) public payable returns (uint256) {
      require(_owns(msg.sender, _momId), "Not own kitty");
      require(_owns(msg.sender, _dadId), "Not own kitty");
      require(_momId != _dadId, "Lets not do this");

      Kitty storage mom = _kitties[_momId];
      Kitty storage dad = _kitties[_dadId];
      
      uint256 _newdna = _mixDna(mom.genes, dad.genes);
      uint256 _generation = max(mom.generation, dad.generation).add(1);

      uint256 newKittyId = _createKitty(
        _momId,
        _dadId,
        _generation,
        _newdna,
        msg.sender
      );

      _kittyToChildren[_dadId].push(newKittyId);
      _kittyToChildren[_momId].push(newKittyId);

      return newKittyId;
    }

    /**
     * @notice Get all the children of a kittyId
     * @param _kittyId the id of the mom
     * @return array of ids of the children
     */
    function getChildren(uint _kittyId) view public returns (uint256[] memory) {
      uint256[] memory children = _kittyToChildren[_kittyId];
      return children;
    }
}

pragma solidity 0.8.0;

import "./KittyMinting.sol";

/**
 * @title The KittyCore contract.
 * @author Adam Southey
 * @dev This contract is split in the following way:
 *      - KittyBase: This is where we define the most fundamental code shared throughout the core
 *             functionality. This includes our main data storage, constants and data types, plus
 *             internal functions for managing these items.
 *      - KittyOwnership: This provides the methods required for basic non-fungible token
 *      - KittyBreeding: This file contains the methods necessary to breed cats together
 *      - KittyMinting: This final facet contains the functionality we use for creating new gen0 cats.
 */
contract KittyCore is KittyMinting {
    /**
     * @notice Returns all the relevant information about a specific kitty
     * @param _kittyId the id of the kitty to get information from
     */
    function getKitty(uint256 _kittyId)
        public
        view
        returns (
            uint256 genes,
            uint256 birthTime,
            uint256 dadId,
            uint256 momId,
            uint256 generation
        )
    {
        Kitty storage kitty = _kitties[_kittyId];

        birthTime = uint256(kitty.birthTime);
        dadId = uint256(kitty.dadId);
        momId = uint256(kitty.momId);
        generation = uint256(kitty.generation);
        genes = kitty.genes;
    }
}

pragma solidity 0.8.0;

import "./KittyBreeding.sol";
import "./utils/SafeMath.sol";

/**
 * @title The KittyMinting contract responsible to create kitties.
 * @author Adam Southey
 */
contract KittyMinting is KittyBreeding {
    using SafeMath for uint256;
    /// @dev Limits the number of cats the contract owner can ever create.
    uint256 public constant CREATION_LIMIT_GEN0 = 100;

    /// @dev Counts the number of cats the contract owner has created.
    uint256 public gen0Count;

    /**
     * @notice Creates a new gen0 kitty
     * @dev Can only be called by owner and when limit has not be reached
     * @return The id of the created kitty
     */
    function createGen0Kitty(uint256 _genes) external onlyOwner returns (uint256) {
        require(gen0Count < CREATION_LIMIT_GEN0, "Limit gen0 reached");

        gen0Count = gen0Count.add(1);

        return _createKitty(0, 0, 0, _genes, msg.sender);
    }
}

pragma solidity 0.8.0;

import "./KittyBase.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Receiver.sol";

/**
 * @title The contract that handles ownership, Fully ERC721 (and ERC165) compliant, and
 * compliance withERC721Metadata and ERC721Enumerable
 * @author Adam Southey
 */
contract KittyOwnership is KittyBase, IERC721 {
    string public constant name = "CryptoKitties";
    string public constant symbol = "CAT";

    /**
     * @dev Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     *which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
     */
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    /**
     * @dev Interface id's to provide via supportsInterface
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @notice Query if a contract implements an interface
     * @param _interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     *  uses less than 30,000 gas.
     * @return true if the contract implements _interfaceId and
     *  _interfaceId is not 0xffffffff, false otherwise
     */
    function supportsInterface(bytes4 _interfaceId) override
        external
        view
        returns (bool)
    {
        return (_interfaceId == _INTERFACE_ID_ERC721 ||
            _interfaceId == _INTERFACE_ID_ERC165);
    }

    /**
     * @notice Count all Kitties assigned to an owner
     * @dev [ERC721] Kitties assigned to the zero address are considered invalid, and this
     * function throws for queries about the zero address
     * @param _owner The address to check
     * @return The address of the owner of the kitty
     */
    function balanceOf(address _owner) override public view returns (uint256) {
        require(_owner != address(0), "Balance query for the zero address");

        return _ownedKittiesCount[_owner];
    }

    /**
     * @notice Find the owner of an Kitty
     * @dev [ERC721] Kitties assigned to the zero address are considered invalid, and this
     * function throws for queries about the zero address
     * @return the address of the onwer of _kittyId
     */
    function ownerOf(uint256 _kittyId) override public view returns (address) {
        address owner = _kittyIdToOwner[_kittyId];
        require(owner != address(0), "Owner query for nonexistent kitty");

        return owner;
    }

    /**
     * @dev Util function to checks if _kittyId is owned by _address
     * @param _address The address we are validating against.
     * @param _kittyId The kitty id to check
     * @return true when _kittyId is owned by _address, false otherwise
     */
    function _owns(address _address, uint256 _kittyId)
        internal
        view
        returns (bool)
    {
        return ownerOf(_kittyId) == _address;
    }

    /**
     * @dev Util function to checks if _kittyId exists, ie. the owner is not a 0 address
     * @param _kittyId The kitty id to check
     * @return true when _kittyId is a registered token, false otherwise
     */
    function _exists(uint256 _kittyId) internal view returns (bool) {
        address owner = _kittyIdToOwner[_kittyId];
        return owner != address(0);
    }

    /**
     * @dev Util function to checks if address is a contract.
     * @dev WARNING: This method relies in extcodesize, which returns 0 for contracts in
     * construction, since the code is only stored at the end of the
     * constructor execution
     * @param _account The address to check.
     * @return true when _account is a contract, false otherwise
     */
    function _isContract(address _account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line
        assembly {
            size := extcodesize(_account)
        }
        return size > 0;
    }

    /**
     * @dev Checks if the address is authorized to do the tranfsfer. This is
     * is the current owner, an authorized operator, or the approved address for this Kitty.
     * @param _address address to check
     * @param _kittyId kitty id to check
     * @return true when _address is authorized to transfer, false otherwise
     */
    function _isAuthorized(address _address, uint256 _kittyId)
        internal
        view
        returns (bool)
    {
        address _owner = ownerOf(_kittyId);
        return (_address == _owner ||
            getApproved(_kittyId) == _address ||
            isApprovedForAll(_owner, _address));
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     * @param _from address representing the previous owner of the given kitty id
     * @param _to target address that will receive the tokens
     * @param _kittyId The id of the kitty to be transferred
     * @param _data bytes optional data to send along with the call
     * @return True if _to is a valid address, false otherwise
     */
    function _checkOnERC721Received(
        address _from,
        address _to,
        uint256 _kittyId,
        bytes memory _data
    ) internal returns (bool) {
        if (!_isContract(_to)) {
            return true;
        }

        bytes4 returndata = IERC721Receiver(_to).onERC721Received(
            msg.sender,
            _from,
            _kittyId,
            _data
        );

        return (returndata == _ERC721_RECEIVED);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     * @param _from current owner of the kitty
     * @param _to address to receive the ownership of the given kitty id
     * @param _kittyId uint256 id of the kitty to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeTransfer(
        address _from,
        address _to,
        uint256 _kittyId,
        bytes memory _data
    ) internal {
        _transfer(_from, _to, _kittyId);
        require(
            _checkOnERC721Received(_from, _to, _kittyId, _data),
            "transfer to non ERC721Receiver"
        );
    }

    /**
     * @notice Transfers the ownership of an Kitty from one address to another address
     * @dev [ERC721] Transfer implementation with a check on caller if it can accept ERC721
     * Requires
     * - valid token
     * - valid, non-zero _to address (via _transfer)
     * - not to this address to prevent potential misuse (via _transfer)
     * - msg.sender to be the owner, approved, or operator
     * - when the caller is a smart contract, it should accept ERC721 tokens
     * @param _from current owner of the kitty
     * @param _to address to receive the ownership of the given kitty id
     * @param _kittyId uint256 id of the kitty to be transferred
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _kittyId
    ) override public {
        safeTransferFrom(_from, _to, _kittyId, "");
    }

    /**
     * @notice Transfers the ownership of an Kitty from one address to another address
     * @dev [ERC721] This works identically to the other function with an extra data parameter
     * except this function just sets data to ""
     * @param _from current owner of the kitty
     * @param _to address to receive the ownership of the given kitty id
     * @param _kittyId The id of the kitty to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _kittyId,
        bytes memory _data
    ) override public {
        require(_exists(_kittyId), "nonexistent token");
        require(_isAuthorized(msg.sender, _kittyId), "not authorized");

        _safeTransfer(_from, _to, _kittyId, _data);
    }

    /**
     * @notice Transfer ownership of a Kitty -- THE CALLER IS RESPONSIBLE
     *  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING KITTIES OR ELSE
     *  THEY MAY BE PERMANENTLY LOST
     * @dev [ERC721] Transfers the ownership of a given token id to another address
     * Requires
     * - valid token
     * - valid, non-zero _to address (via _transfer)
     * - not to this address to prevent potential misuse (via _transfer)
     * - msg.sender to be the owner, approved, or operator
     * @param _from current owner of the kitty
     * @param _to address to receive the ownership of the given kitty id
     * @param _kittyId id of the kitty to be transferred
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _kittyId
    ) override public {
        require(_exists(_kittyId), "nonexistent token");
        require(_isAuthorized(msg.sender, _kittyId), "not authorized");

        _transfer(_from, _to, _kittyId);
    }

    /**
     * @notice Transfers the ownership of an own Kitty to another address
     * @param _to address to receive the ownership of the given kitty id
     * @param _kittyId id of the kitty to be transferred
     */
    function transfer(address _to, uint256 _kittyId) external {
        safeTransferFrom(msg.sender, _to, _kittyId);
    }

    /**
     * @notice Change or reaffirm the approved address for an kitty
     * @dev [ERC721] The zero address indicates there is no approved address
     * Requires
     * - msg.sender is owner or approved opperator
     * - cannot approve owner
     * @param _to The address.
     * @param _kittyId The kitty id that is approved for
     */
    function approve(address _to, uint256 _kittyId) override public {
        address _owner = ownerOf(_kittyId);
        require(_to != _owner, "approval to current owner");
        require(
            _owns(msg.sender, _kittyId),
            "approve caller is not owner nor approved for all"
        );

        _kittyIdToApproved[_kittyId] = _to;
        emit Approval(_owner, _to, _kittyId);
    }

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage
     * all of `msg.sender`'s assets
     * @dev [ERC721] Emits the ApprovalForAll event.
     * Requires
     * - cannot approve self
     * @param _operator The kitty id
     * @param _approved The approval status
     */
    function setApprovalForAll(address _operator, bool _approved) override public {
        require(_operator != msg.sender, "approval to caller");

        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @notice Get the approved address for a single kitty
     * @dev [ERC721] Get the approval address of the kitty
     * Requires
     * - _kittyId must exist
     * @param _kittyId The kitty id
     * @return The approved address for this kitty, or the zero address if there is none
     */
    function getApproved(uint256 _kittyId) override public view returns (address) {
        require(_exists(_kittyId), "approved query for nonexistent kitty");

        return _kittyIdToApproved[_kittyId];
    }

    /**
     * @notice Query if an address is an authorized operator for another address
     * @dev [ERC721]
     * @param _owner The owner
     * @param _operator The operator
     * @return True if `_operator` is an approved operator for `_owner`, false otherwise
     */
    function isApprovedForAll(address _owner, address _operator)
        override public
        view
        returns (bool)
    {
        return _operatorApprovals[_owner][_operator];
    }

    /**
     * @notice Count kitties tracked by this contract
     * @dev [ERC721Enumerable]
     * @return A count of valid kitties tracked by this contract, where each one of
     *  them has an assigned and queryable owner not equal to the zero address
     */
    function totalSupply() public view returns (uint256) {
        return _kitties.length;
    }

    /**
     * @notice Enumerate valid kitties
     * @dev [ERC721Enumerable]
     * Requires:
     *  - _index < totalSupply()
     * @param _index A counter less than `totalSupply()`
     * @return _index which is the same as the identifier
     */
    function tokenByIndex(uint256 _index) external view returns (uint256) {
        require(_index < totalSupply(), "index out of bounds");
        return _index;
    }

    /**
     * @notice Returns a list of all Kitty IDs assigned to an address.
     * @dev [ERC721Enumerable]
     * Requires
     *  - _index < balanceOf(_owner)
     *  - _owner is  non-zero address
     * @dev Be aware when calling this contract as its quite expensive because it
     * loops through all kitties
     * @param _owner An address where we are interested in kitties owned by them
     * @return The token identifier for the `_index`th kitty assigned to `_owner`,
     *   (sort order not specified)
     */
    function tokensOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        require(_owner != address(0), "Token query for the zero address");

        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        }

        uint256[] memory result = new uint256[](tokenCount);
        uint256 totalKitties = totalSupply();
        uint256 resultIndex = 0;

        uint256 kittyId;

        for (kittyId = 0; kittyId <= totalKitties; kittyId++) {
            if (_kittyIdToOwner[kittyId] == _owner) {
                result[resultIndex] = kittyId;
                resultIndex++;
            }
        }

        return result;
    }

    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested owner.
     * @dev Be aware when calling this contract as its quite expensive because it
     * loops through all kitties. Could potentially be optimized if we save all kitties also
     * in an mapping of owners.
     * @param _owner address owning the tokens list to be accessed
     * @param _index uint256 representing the index to be accessed of the requested tokens list
     * @return uint256 token ID at the given index of the tokens list owned by the requested address
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        public
        view
        returns (uint256)
    {
        require(_index < balanceOf(_owner), "index out of bounds");
        return tokensOfOwner(_owner)[_index];
    }
}

pragma solidity 0.8.0;

import "./utils/Ownable.sol";
import "./KittyCore.sol";

/**
 * @title The MarketPlace contract.
 * @author Adam Southey
 * @dev It takes ownership of the kitty for the duration that it is on the marketplace
 */
contract MarketPlace is Ownable {
    using SafeMath for uint256;

    struct Offer {
        address payable seller;
        uint256 price;
        uint256 index;
        uint256 tokenId;
        bool active;
    }

    event MarketTransaction(string TxType, address owner, uint256 tokenId);
    
    KittyCore private _kittyContract;
    uint256[] private _offeredTokenIds;
    mapping(uint256 => Offer) private _tokenIdToOffer;

    /**
     * @notice Set the current KittyContract address and initialize the instance of Kittycontract.
     * @dev Requirement: Only the contract owner can call.
     * @param _kittyContractAddress the address of the KittyCore contract to interact with
     */
    function setKittyCoreContract(address _kittyContractAddress)
        public
        onlyOwner
    {
        _kittyContract = KittyCore(_kittyContractAddress);
    }

    constructor(address _kittyContractAddress) public {
        setKittyCoreContract(_kittyContractAddress);
    }

    function getOffer(uint256 _tokenId)
        external
        view
        returns (
            address seller,
            uint256 price,
            uint256 index,
            uint256 tokenId,
            bool active
        )
    {
        Offer storage offer = _tokenIdToOffer[_tokenId];
        return (
            offer.seller,
            offer.price,
            offer.index,
            offer.tokenId,
            offer.active
        );
    }

    function getAllTokenOnSale()
        external
        view
        returns (uint256[] memory listOfOffers)
    {
        return _offeredTokenIds;
    }

    /**
     * @dev checks if an address owns a kitty
     * @param _address the address to check the ownership of
     * @param _tokenId the id of the kitty to check
     * @return True if the address owns the kitty, false otherwise
     */
    function _ownsKitty(address _address, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        return (_kittyContract.ownerOf(_tokenId) == _address);
    }

    /**
     * @notice Creates a new offer for _tokenId for the price _price.
     * @dev Requirements:
     * Only the owner of _tokenId can create an offer.
     * There can only be one active offer for a token at a time.
     * Marketplace contract (this) needs to be an approved operator when the offer is created.
     * @param _price the price of the new offer
     * @param _tokenId the id of the kitty
     */
    function setOffer(uint256 _price, uint256 _tokenId) external {
        require(_ownsKitty(msg.sender, _tokenId), "Not the owner");
        require(_tokenIdToOffer[_tokenId].price == 0 , "Already offered");

        require(
            _kittyContract.isApprovedForAll(msg.sender, address(this)),
            "Marketplace needs approval"
        );

        Offer memory _offer = Offer({
            seller: payable(msg.sender),
            price: _price,
            active: true,
            tokenId: _tokenId,
            index: _offeredTokenIds.length
        });

        _tokenIdToOffer[_tokenId] = _offer;
        _offeredTokenIds.push(_tokenId);

        emit MarketTransaction("Create offer", msg.sender, _tokenId);
    }

    /**
     * @dev In order to easily requests all _offeredTokenIds, we need to track an array of all the _offeredTokenIds,
     * this needs to be updated on removal. For this we will swap the last element with the current element, 
     * and update the corresponding index in the struct.
     * Note that this is only needed in order to easily request all active _offeredTokenIds as an array
     * Inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/04a1b21874e02fd3027172bf208d9658b886b658/contracts/token/ERC721/ERC721Enumerable.sol
     * @dev Requirement: Only the seller of _tokenId can remove an offer.
     * @param _tokenId the id of the kitty of which its offer needs to remove
     */
    function _removeOffer(uint256 _tokenId) private {
        // Remove from array: move the last token to the current token position
        uint256 lastTokenIndex = _offeredTokenIds.length.sub(1);
        uint256 tokenIndex = _tokenIdToOffer[_tokenId].index;
        uint256 lastTokenId = _offeredTokenIds[lastTokenIndex];

        _offeredTokenIds[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _tokenIdToOffer[lastTokenId].index = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        _offeredTokenIds.pop();
        _tokenIdToOffer[_tokenId].index = 0;
        
        // Remove from mapping
        delete _tokenIdToOffer[_tokenId];
    }

    /**
     * @notice Removes an existing offer.
     * @dev see _removeOffer
     */
    function removeOffer(uint256 _tokenId) external {
        Offer memory offer = _tokenIdToOffer[_tokenId];
        require(offer.seller == msg.sender, "Not the owner");

        _removeOffer(_tokenId);

        emit MarketTransaction("Remove offer", msg.sender, _tokenId);
    }

    /**
     * @notice Executes the purchase of _tokenId.
     * Sends the funds to the seller and transfers the token using transferFrom in Kittycontract.
     * @dev Requirement:
     * The msg.value needs to equal the price of _tokenId
     * There must be an active offer for _tokenId
     */
    function buyKitty(uint256 _tokenId) external payable {
        Offer memory offer = _tokenIdToOffer[_tokenId];
        require(offer.price > 0, "No active offer");
        require(msg.value == offer.price, "The price is incorrect");

        // Important: delete the kitty from the mapping BEFORE paying out to prevent reentry attacks
        _removeOffer(_tokenId);

        // Transfer the funds to the seller
        // TODO: make this logic pull instead of push
        if (offer.price > 0) {
            offer.seller.transfer(offer.price);
        }

        // Transfer ownership of the kitty
        _kittyContract.transferFrom(offer.seller, msg.sender, _tokenId);

        emit MarketTransaction("Buy", msg.sender, _tokenId);
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
contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}