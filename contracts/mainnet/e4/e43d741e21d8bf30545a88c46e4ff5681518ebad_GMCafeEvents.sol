/**
 *Submitted for verification at polygonscan.com on 2022-09-23
*/

// File: @openzeppelin/[email protected]/utils/introspection/IERC165.sol


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

// File: @openzeppelin/[email protected]/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/[email protected]/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/[email protected]/token/ERC1155/extensions/IERC1155MetadataURI.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// File: @openzeppelin/[email protected]/utils/Context.sol


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

// File: @openzeppelin/[email protected]/access/Ownable.sol


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

// File: GMCafeMoments.sol

/*                              gweMBMEBBBMBMEBMBwg_.                                                           
                           aeMMEPP"  ' '. .  ..""^BMMBMe_'                             )BE   zEE .ZEEBL  JBBMg. 
                      __eEMPP .                     .`?RBEe,.                          $BM$_JMMBLJMEOEBL BEPEEE 
                    _BMMK'                              ''ME$L.                        $EEMEMBMB'5EE MMK$BE.]ME 
                  _BMB'                                    .$EE,   [email protected]@BBBEEB.          5MB$EBEEE'MMK'MBKEME BEf 
  [email protected],,.zB$"                                         EBMMBBF``' .'EEk         MM('".]B$.EMKJBB BBL,EEP 
 JB$`. .. `?PKEMBEMBMEBg_                           _,we_      SBB.        ]ME        .BBP   $EE EMMME`.BBMMEK  
 $MP           .  . ``FBMe                          EEFEEE     .BEL       .$MK        .^^    1M   "F^.  .APP.   
 1BE'                   ^B$.                       JBB .BMK     JME      .BEK                                   
  1MB,                   [EE                        BB, 5B[     )E$    ,gBB`            .EEk                    
    BEB                 .BMP                        ?BEgME.    _BEBgLeMMBC_'          ,e$EM^                    
    .`MBMg,            gEBE'  ',,        eEBe,,,  . [email protected][email protected]         $MEP`                     
      ,BMBEMEew_L,_-wMBBR`    'RBMBewwBEBE"?PBBMEBMEER^`?RRMBM^`.  @e.    'BB.                                  
  __eBBP`''''^RRRBRRP`..        ..""YY`                     '.wgwL.'MBE  _wEE                                   
[email protected]`.                      Lgg_              _eMg.        JEBEMMe  3MMME$K                                    
$BP.                       JBBEBEB.           yBBBMBy       $EBMEBE   $ME.                                      
&EK_         .,            \MBEBBE.           "^   `.        '^R^ '   .BM'                                      
 `[email protected]@@BEMBK           ' RRK".                                     MB                                       
     BE$^YY"` .                                                       JM$                 https://www.gmcafe.io/
     ^".                                                              .*/
/// @author raffy.eth

pragma solidity ^0.8.17;





contract GMCafeEvents is Ownable, IERC1155, IERC1155MetadataURI {
   
	function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
		return interfaceId == type(IERC1155).interfaceId
			|| interfaceId == type(IERC1155MetadataURI).interfaceId;
	}

	string public constant name = "Good Morning Cafe Moments";
	string public constant symbol = "GMOOMENTS";

	string private _uri = "https://gmcafe.s3.us-east-2.amazonaws.com/gmoo/events/{id}.json";

	uint256 private _tokenMax;
	mapping(uint256 => uint256) private _tokenSupply;
	mapping(uint256 => mapping(address => uint256)) private _balances;
	mapping(address => mapping(address => bool)) private _operatorApprovals;

	function withdraw() onlyOwner public {
		require(address(this).balance != 0, "empty");
		payable(msg.sender).transfer(address(this).balance);
	}
	function setURI(string calldata s) onlyOwner public {
		_uri = s;
	}
	function uri(uint256) external view returns (string memory) {
		return _uri;
	}

	function countTokens() public view returns (uint256) {
		return _tokenMax;
	}
	function tallyTokens() public view returns (uint256[] memory tally) {
		unchecked {
			uint256 acc;
			uint256 end = _tokenMax + 1;
			tally = new uint256[](end);
			for (uint256 i = 1; i < end; i++) {
				uint256 supply = _tokenSupply[i];
				tally[i] = supply;
				acc += supply;
			}
			tally[0] = acc;
		}
	}
    function balancesOf(address owner) public view returns (uint256[] memory counts) {
        unchecked {
            uint256 acc;
			uint256 end = _tokenMax + 1;
			counts = new uint256[](end);
			for (uint256 i = 1; i < end; i++) {
				uint256 count = balanceOf(owner, i);
				counts[i] = count;
				acc += count;
			}
			counts[0] = acc;
        }
    }

	function exists(uint256 token) public view returns (bool) {
		return _tokenSupply[token] > 0;
	}
	function totalSupply(uint256 token) public view returns (uint256) {
		return _tokenSupply[token];
	}
	function balanceOf(address owner, uint256 token) public view returns (uint256) {
		return _balances[token][owner];
	}
	function balanceOfBatch(address[] calldata owners, uint256[] calldata tokens) public view returns (uint256[] memory counts) {
		unchecked {
			uint256 n = owners.length;
			require(n == tokens.length, "length");
			counts = new uint256[](n);
			for (uint256 i; i < n; i++) {
				counts[i] = _balances[tokens[i]][owners[i]];
			}
		}
	}

	function airdropBatch(address[] calldata owners, uint256 token, uint256 count) public onlyOwner {
		unchecked {
			require(token != 0, "token");
			require(count != 0, "count");
			uint256 n = owners.length;
			require(n != 0, "length");
			for (uint256 i; i < n; i++) {
				address owner = owners[i];
				require(owner != address(0), "0x0");
				_balances[token][owner] += count;
				emit TransferSingle(msg.sender, address(0), owner, token, count);
			}
			_tokenSupply[token] += n * count;
			if (token > _tokenMax) _tokenMax = token;
		}
	}

	function setApprovalForAll(address operator, bool approved) public {
		require(msg.sender != operator, "approve owner");
		_operatorApprovals[msg.sender][operator] = approved;
		emit ApprovalForAll(msg.sender, operator, approved);
	}
	function isApprovedForAll(address owner, address operator) public view returns (bool) {
		return _operatorApprovals[owner][operator];
	}

	function safeTransferFrom(address from, address to, uint256 token, uint256 count, bytes calldata data) public {
		unchecked {
			require(to != address(0), "0x0");
			require(from == msg.sender || isApprovedForAll(from, msg.sender), "approval");
			uint256 have = _balances[token][from];
			require(have >= count, "count");
			_balances[token][from] = have - count;
			_balances[token][to] += count;
			emit TransferSingle(msg.sender, from, to, token, count);
			if (to.code.length != 0) {
				try IERC1155Receiver(to).onERC1155Received(msg.sender, from, token, count, data) returns (bytes4 response) {
					if (response != IERC1155Receiver.onERC1155Received.selector) {
						revert("contract rejected");
					}
				} catch Error(string memory reason) {
					revert(reason);
				} catch {
					revert("dumb contract");
				}
			}
		}
	}
	function safeBatchTransferFrom(address from, address to, uint256[] calldata tokens, uint256[] calldata counts, bytes calldata data) public {
		unchecked {
			require(to != address(0), "0x0");
			require(from == msg.sender || isApprovedForAll(from, msg.sender), "approval");
			uint256 n = tokens.length;
			require(n == counts.length, "length");
			for (uint256 i; i < n; i++) {
				uint256 token = tokens[i];
				uint256 count = counts[i];
				uint256 have = _balances[token][from];
				require(have >= count, "amount");
				_balances[token][from] = have - count;
				_balances[token][to] += count;
			}
			emit TransferBatch(msg.sender, from, to, tokens, counts);
			if (to.code.length != 0) {
				try IERC1155Receiver(to).onERC1155BatchReceived(msg.sender, from, tokens, counts, data) returns (bytes4 response) {
					if (response != IERC1155Receiver.onERC1155Received.selector) {
						revert("contract rejected");
					}
				} catch Error(string memory reason) {
					revert(reason);
				} catch {
					revert("dumb contract");
				}
			}
		}
	}

}