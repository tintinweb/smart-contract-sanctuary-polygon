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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ICheers.sol";
import "./interfaces/IIAmCheersNFT.sol";
import "./interfaces/ICheersData.sol";
import "./ProjectPool.sol";

contract Cheers is ICheers, Ownable {
  // CHERトークンのアドレス
  IERC20 public cher;
  IIAmCheersNFT public iAmCheersNFT;
  ICheersData public cheersData;

  // 既にmintしたかどうか
  mapping(address => bool) public hasMinted;

  // CHERトークンのアドレスをセット
  // @note 管理者のみ実行　管理者とは？
  function setCherTokenAddress(address _cherTokenAddress) public {
    require(address(cher) != _cherTokenAddress, "Address already registered");
    cher = IERC20(_cherTokenAddress);
  }

  // CHERトークンのコントラクトアドレスを取得
  function getCherTokenAddress() public view returns (address) {
    return address(cher);
  }

  // CheersDataのコントラクトアドレスを取得
  function getCheersDataAddress() public view returns (address) {
    return address(cheersData);
  }

  // iAmCheersNFTのアドレスを変更
  function setIAmCheersNFTAddress(address _iAmCheersNFT) external onlyOwner {
    iAmCheersNFT = IIAmCheersNFT(_iAmCheersNFT);
  }

  // cheersDataのアドレスを変更
  function setCheersDataAddress(address _cheersData) external onlyOwner {
    cheersData = ICheersData(_cheersData);
  }

  // 新しいオーナー（User/DAO）を作成
  function addNewOwner(
    string memory _ownerName,
    string memory _ownerProfile,
    string memory _ownerIcon,
    bool _isDao
  ) external {
    // iamCheersNFTをmintしていないことを確認
    require(iAmCheersNFT.balanceOf(msg.sender) == 0, "already minted!");

    if (!hasMinted[msg.sender]) {
      hasMinted[msg.sender] = true;

      // cheersDataに新しいオーナーを追加
      cheersData.addOwnerData(msg.sender, _ownerName, _ownerProfile, _ownerIcon, _isDao);
    }

    // iAmCheersNFTをmint
    iAmCheersNFT.mintNft(msg.sender);
  }

  // チャレンジする（ProjectPoolを作成、CheersDataを追加）
  function challenge(
    address _projectBelongDaoAddress,
    string memory _projectName,
    string memory _projectContent,
    string memory _projectReword
  ) public returns (address) {
    ProjectPool projectPool = new ProjectPool(
      msg.sender,
      _projectBelongDaoAddress,
      _projectName,
      _projectContent,
      _projectReword,
      address(cheersData),
      address(cher)
    );

    cheersData.addProject(
      msg.sender,
      address(projectPool),
      _projectBelongDaoAddress,
      _projectName,
      _projectContent,
      _projectReword
    );
    return address(projectPool);
  }

  // cheerする
  function cheer(address projectPoolAddress, uint256 _cheerCherAmount, string memory _cheerMessage) public {
    require(cher.balanceOf(msg.sender) >= _cheerCherAmount, "Not enough");
    // Cheer済みフラグをオンにする
    cheersData.addCheerProject(msg.sender, projectPoolAddress);
    cheersData.addCheerData(projectPoolAddress, msg.sender, block.timestamp, _cheerMessage, _cheerCherAmount);
    ProjectPool(projectPoolAddress).receiveCher(_cheerCherAmount, msg.sender);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IIAmCheersNFT.sol";
import "./ICheersData.sol";

interface ICheers {
  // CHERトークンのアドレスをセット
  function setCherTokenAddress(address _cherTokenAddress) external;

  // CHERトークンのコントラクトアドレスを取得
  function getCherTokenAddress() external view returns (address);

  // CheersDataのコントラクトアドレスを取得
  function getCheersDataAddress() external view returns (address);

  // iAmCheersNFTのアドレスを変更
  function setIAmCheersNFTAddress(address _iAmCheersNFT) external;

  // cheersDataのアドレスを変更
  function setCheersDataAddress(address _cheersData) external;

  // 新しいオーナー（User/DAO）を作成
  function addNewOwner(
    string memory _ownerName,
    string memory _ownerProfile,
    string memory _ownerIcon,
    bool _isDao
  ) external;

  // チャレンジする（ProjectPoolを作成、CheersDataを追加）
  function challenge(
    address _projectBelongDaoAddress,
    string memory _projectName,
    string memory _projectContent,
    string memory _projectReword
  ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../shared/SharedStruct.sol";

interface ICheersData {
  function addOwnerData(
    address _daoAddress,
    string memory _daoName,
    string memory _daoProfile,
    string memory _daoIcon,
    bool _isDao
  ) external;

  function getAllDaosData() external view returns (SharedStruct.Owner[] memory);

  function addCheerData(
    address _projectAddress,
    address _owner,
    uint256 _creationTime,
    string memory _message,
    uint256 _cherAmount
  ) external;

  function getCheersDataByCheerer(address _ownerAddress) external view returns (SharedStruct.Cheer[] memory);

  function getCheersDataOfProject(address _projectAddress) external view returns (SharedStruct.Cheer[] memory);

  // PROJECT追加
  function addProject(
    address _challenger,
    address _projectAddress,
    address _belongDao,
    string memory _projectName,
    string memory _projectContent,
    string memory _projectReword
  ) external;

  // アドレスごとのProject取得
  function getProjectsDataOfChallenger(address _challenger) external view returns (SharedStruct.Project[] memory);

  // Cheer済みフラグをオンにする
  function addCheerProject(address _cheererAddress, address _projectAddress) external;

  // Cheer済みフラグをオフにする
  function removeCheerProject(address _cheererAddress, address _projectAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address to, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IIAmCheersNFT is IERC721 {
  function hashMsgSender(address) external view returns (uint256);

  function mintNft(address _ownerAddress) external;

  function burnNft() external;

  function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IProjectPool {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IProjectPool.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ICheers.sol";
import "./interfaces/ICheersData.sol";
import "./shared/SharedStruct.sol";

// projectのプール
contract ProjectPool is IProjectPool {
  // このprojectのchallenger
  address public projectChallengerAddress;
  // このprojectが所属しているDAOアドレス
  address public projectBelongDaoAddress;
  // project名
  string public projectName;
  // projectコンテンツ
  string public projectContent;
  // projectリワード
  string public projectReword;
  // project作成時刻
  uint256 public projectCreationTime;
  // projectの累計CHERトークン数
  uint256 public totalCherAmount;

  // CHERトークンのコントラクト
  IERC20 public cher;
  // cheersのコントラクト
  ICheers public cheers;
  // cheersDataのコントラクト
  ICheersData public cheersData;

  constructor(
    address _projectChallengerAddress,
    address _projectBelongDaoAddress,
    string memory _projectName,
    string memory _projectContent,
    string memory _projectReword,
    address _cheersData,
    address _cherTokenAddress
  ) {
    cheers = ICheers(msg.sender);
    cheersData = ICheersData(_cheersData);
    cher = IERC20(_cherTokenAddress);

    projectChallengerAddress = _projectChallengerAddress;
    projectBelongDaoAddress = _projectBelongDaoAddress;
    projectName = _projectName;
    projectContent = _projectContent;
    projectReword = _projectReword;
    projectCreationTime = block.timestamp;
  }

  // このprojectをcheerする
  function receiveCher(uint256 _cheerCherAmount, address _from) public {
    require(cher.balanceOf(_from) >= _cheerCherAmount, "Not enough");
    cher.transferFrom(_from, address(this), _cheerCherAmount);
    _distributeCher(_cheerCherAmount);
  }

  // CHERトークンをステークホルダーに分配する
  function _distributeCher(uint256 _cheerCherAmount) private {
    // ⚠️端数処理がどうなるか？？？
    // このProjectに投じられた分配前の合計
    totalCherAmount += _cheerCherAmount;
    // cheer全員の分配分
    uint256 cheerDistribute = (_cheerCherAmount * 70) / 100;
    // challengerの分配分
    uint256 challengerDistribute = (_cheerCherAmount * 25) / 100;
    // daoの分配分
    uint256 daoDistribute = _cheerCherAmount - cheerDistribute - challengerDistribute;
    // cheer全員の分配分を投じたcher割合に応じ分配
    for (uint256 i = 0; i < cheersData.getCheersDataOfProject(address(this)).length; i++) {
      bool sent = cher.transfer(
        cheersData.getCheersDataOfProject(address(this))[i].cheerAddress,
        (cheerDistribute * cheersData.getCheersDataOfProject(address(this))[i].cheerCherAmount) / totalCherAmount
      );
      require(sent, "transfer failed");
    }
    // challengerのPoolへ分配
    cher.transfer(projectChallengerAddress, challengerDistribute);
    // 所属するDAOへ分配
    cher.transfer(projectBelongDaoAddress, daoDistribute);
  }

  // このプールの現在のCHERトークン残高
  function getCherBalance() public view returns (uint256) {
    return cher.balanceOf(address(this));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library SharedStruct {
  struct Owner {
    uint256 ownerCreationTime;
    address ownerAddress;
    string ownerName;
    string ownerProfile;
    string ownerIcon;
  }

  struct Project {
    uint256 projectCreationTime;
    address projectChallengerAddress;
    address projectAddress;
    address projectBelongDaoAddress;
    string projectName;
    string projectContent;
    string projectReword;
  }

  struct Cheer {
    uint256 cheerCherAmount;
    uint256 cheerCreationTime;
    address cheerProjectAddress;
    address cheerAddress;
    string cheerMessage;
  }
}