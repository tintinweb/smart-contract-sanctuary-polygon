// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BCOwner is
        Ownable
{

    //// Contract name and symbol
    string public name;
    string public symbol;
    //// 発行上限
    uint256 public maxtokenId = 25999;

    // 許可されたコントラクトアドレス
    mapping(address => bool) public _allowedContracts;

    // BC Generative トークンIdごとの所有ウォレットアドレス
    mapping(uint256 => address) public _BCGenerativeHolders;
    // BC Generative トークンIdごとの所有ウォレットアドレスの存在有無
    mapping(uint256 => bool) public _setHolders;


    constructor() {}


    // 書き込み　BC Generative ウォレットごとの所有Token Id
    function setBCGenerativeHolders(uint256[] memory _tokenIds, address[] memory _holders) public onlyOwner {
        // コントラクトからの呼び出し防止
        require(tx.origin == msg.sender, "contract cannot call this function");

        // Idとアドレスの入力した数が同じである事
        require(_tokenIds.length == _holders.length, "Id and address each length does not match");

        // Idごとにアドレスを登録するループ関数
        for (uint256 i = 0; i < _tokenIds.length; i++) {

            // tokenIdの値 を i に置き換え
            uint256 tokenId = _tokenIds[i];

            // maxtokenidを超えていないかチェック
            require(tokenId <= maxtokenId, "Token ID exceed max id");

            // holder addressの値 を i に置き換え
            address holder = _holders[i];

            // setされたトークンIdは trueにする
            _setHolders[tokenId] = true;

            // tokenIdに対応するholder addressを書き込み
            _BCGenerativeHolders[tokenId] = holder;
        }
    }

    // BCownerを呼び出せるアドレスを管理　アドレス追加
    function setAllowedContract(address _contract, bool _allowed) public onlyOwner {
        _allowedContracts[_contract] = _allowed;
    }

    // BCownerを呼び出せるアドレスを管理　アドレス削除
    function revokeAllowedContract(address _contract) public onlyOwner {
        _allowedContracts[_contract] = false;
    }

    // NameとSymbolの設定
    function setNameAndSymbol(string memory _name, string memory _symbol) public onlyOwner {
        delete name;
        delete symbol;
        name = _name;
        symbol = _symbol;
    }

    // Max Token Idの設定
    function setMaxTokenId(uint256 _maxtokenId) public onlyOwner {
        delete maxtokenId;
        maxtokenId = _maxtokenId;
    }

    // オーナー移管
    function transferOwnership(address newOwner) public override onlyOwner {
        _transferOwnership(newOwner);
    }

    // 誤ってオーナーアドレスがゼロアドレスになることを回避する
    function renounceOwnership() public override onlyOwner {
        _transferOwnership(address(msg.sender));
    }

}