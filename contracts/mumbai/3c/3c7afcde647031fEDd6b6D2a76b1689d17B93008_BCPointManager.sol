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

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IBCOwner.sol";

contract BCPointManager is
//        ERC721Psi,
        Ownable
{

    // BCOwner コントラクトアドレス
    IBCOwner public BCOwner;

  //// Contract name and symbol
    string public name;
    string public symbol;
  //// 発行上限
    uint256 public maxtokenId = 25999;
  ////　ステーキング関連 ////
    //　ステーキング開始時間　初期値 リリース日 6/11 午後12時（1686452400）
    uint256 public basetime; // = 1686452400;
    //　ステーキング必要時間の最小単位　初期値
    uint256 private constant STAKING_TIME = 10;
    //　貯まるポイントの最小単位　初期値
    uint256 private constant STAKING_POINTS = 60;
    // 各トークンIdごとのステーキング開始時間　最初は0でbasetime読みに行く
    mapping(uint256 => uint256) public _stakingStartTimesByIds;
    // 各トークンIdごとのステーキング積算ポイント
    mapping(uint256 => uint256) public _stakingPointsByIds;
    // ウォレットがクレームしたポイント
    mapping(address => uint256) public _pointsByAddresses;
    // ウォレットが使用済みのポイント
    mapping(address => uint256) public _usedPointsByAddresses;

    // 許可されたコントラクトアドレス
    mapping(address => bool) private allowedContracts;


    constructor() {}

    /**
     * ステーキング用の関数
     */

    /// ステーキング経過時間の確認　ミント後からのトータル時間　トークンIdごと
    function getTotalStakingElapsedTime(uint256 _tokenId) public view returns (uint256) {
        // maxtokenidを超えていないかチェック
        require(_tokenId <= maxtokenId, "Token ID exceed max id");
        uint256 currentTime = block.timestamp;
        uint256 elapsedTime = currentTime - basetime;
        return elapsedTime;
    }

    /// ステーキング経過時間の確認　ポイントが引き出されたIdは、リセットされたスタート時間からの経過時間を計算　トークンIdごと
    function getStakingElapsedTime(uint256 _tokenId) public view returns (uint256) {
        // maxtokenidを超えていないかチェック
        require(_tokenId <= maxtokenId, "Token ID exceed max id");
        uint256 currentTime = block.timestamp;
        if (_stakingStartTimesByIds[_tokenId] == 0) {
            uint256 elapsedTime = currentTime - basetime;
            return elapsedTime;
        }
            uint256 elapsedTime2 = currentTime - _stakingStartTimesByIds[_tokenId];
            return elapsedTime2;
    }

    // 各トークンIdごとのミント直後からのステーキング積算ポイントの呼び出し
    function checkStakingPointsOfTokenId(uint256 _tokenId) public view returns (uint256) {
        // maxtokenidを超えていないかチェック
        require(_tokenId <= maxtokenId, "Token ID exceed max id");
        uint256 totalpoint = (getStakingElapsedTime(_tokenId) / STAKING_TIME) * STAKING_POINTS;
        return totalpoint;
    }

/*
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
*/

    // BC Generative Holderのアドレス確認
    function getBCHoldersAddress(uint256 _tokenId) public view returns (address) {
        return BCOwner._BCGenerativeHolders(_tokenId);
    }

    // BC Generative のtokenIdにHolderが存在するか確認
    function getHolderExistOrNot(uint256 _tokenId) public view returns (bool) {
        return BCOwner._setHolders(_tokenId);
    }

    // BC Generative のtokenIdにHolderが存在するか確認
    function getAllowedContracts(address _contract) public view returns (bool) {
        return BCOwner._allowedContracts(_contract);
    }


    /// ステーキングポイントをウォレットに移動。
    function claimStakingPointsOfTokenId(address _to, uint256[] memory _tokenIds) public onlyOwner {

        // コントラクトからの呼び出し防止
        require(tx.origin == msg.sender, "contract cannot call this function");

        // クレームポイントの初期値
        uint256 totalPoints = 0;

        // 対象のIdごとにクレーム
        for (uint256 i = 0; i < _tokenIds.length; i++) {

            // tokenIdの値 を i に置き換え
            uint256 tokenId = _tokenIds[i];

            // maxtokenidを超えていないかチェック
            require(tokenId <= maxtokenId, "Token ID exceed max id");

            // 指定のtokenIdに所有ウォレットアドレスが存在しているかのチェック
            require(getHolderExistOrNot(tokenId) == true, "Token ID does not exist");

            // callerが指定のtokenIdを所有しているかのチェック
            require(getBCHoldersAddress(tokenId) == msg.sender, "Caller does not own this token ID");

            // 指定TokenIdに貯まっているポイントをチェックし、記録する
            _stakingPointsByIds[tokenId] = checkStakingPointsOfTokenId(tokenId);

            // 指定TokenIdに格納されたポイントをtotalポイントとする
            totalPoints += _stakingPointsByIds[tokenId];

            // 指定TokenIdに格納されたポイントをゼロにする。
            _stakingPointsByIds[tokenId] = 0;

            // 引き出した後は、ステーキング開始時間もリセット
            _stakingStartTimesByIds[tokenId] = block.timestamp;
        }

    // 指定ウォレットにtotalポイントを記録する。
        _pointsByAddresses[_to] += totalPoints;
    }


    // ウォレットごとのポイント呼び出し関数
    function getPointByAddresses(address _address) public view returns (uint256) {
        return _pointsByAddresses[_address];
    }

    // usePoints関数を叩けるアドレスを管理 bool
    function setAllowedContract(address _contract, bool _allowed) public onlyOwner {
        allowedContracts[_contract] = _allowed;
    }

    // usePoints関数を叩けるアドレスをfalse
    function revokeAllowedContract(address _contract) public onlyOwner {
        allowedContracts[_contract] = false;
    }

    /// ステーキングポイントを使用してNFTガチャをする。
    function usePoints(uint256 _usePoints, address _from) public {

        // 許可されたアドレスからのみ関数が呼び出されていること
        require(allowedContracts[msg.sender], "Not called from an allowed contract");

        // 使用するポイントが所有ポイントを超えないこと
        require(_usePoints <= _pointsByAddresses[_from], "Not enough points");

        // コントラクトからの呼び出し防止
/*        require(tx.origin == msg.sender, "Cannot usePoint from contracts");

        // 使用ポイントはゼロより大きく、かつ必要ポイント数以上であること
        require(_usePoints > 0 && _usePoints >= pointForOnegacha , "not enough point for gacha");

        // 使用ポイントは、必要ポイントの整数倍であること
        require(_usePoints % pointForOnegacha == 0 , "any modulo amount cannot be allowed");

        // ガチャミント最大可能数を算出
        uint256 maxamount = getGachaMintAmountByAddress(msg.sender);

        // ミントするIDをランダムに決める（Id番号＝種類の数で割った余り（5なら0~4がID）
        uint256 gacha = uint8(random(string(abi.encodePacked(Strings.toString(block.timestamp),Strings.toString(maxamount))))) % gachaVariants;

        // StartId を考慮した、ガチャ当選結果ＩＤの決定
        uint256 result = gacha + gachaStartId;

        // ガチャミント数を算出
        uint256 amount = _usePoints / pointForOnegacha;

        // ガチャミント
        NFTgacha.gachaMint(msg.sender, result, amount);
*/
        // 使用済みポイントをウォレットから差し引く
        _pointsByAddresses[_from] -= _usePoints;

        // ウォレットの使用済みポイントを記録する
        _usedPointsByAddresses[_from] += _usePoints;

/*        // ウォレットのガチャミント済み数をカウント
        _gachaMintedCount[msg.sender] += maxamount;
*/
    }

    ///TokenIdに溜まったポイントとは関係なく、 ポイントを手動でウォレットに登録。
    function addPoints(address _to, uint256 _addpoints) public onlyOwner {
       _pointsByAddresses[_to] += _addpoints;
    }

    ///TokenIdに溜まったポイントとは関係なく、 ポイントを手動で複数ウォレットに一括登録。
    function addPointsToMultipleWallets(address[] memory wallets, uint256[] memory points) public onlyOwner {
       require(wallets.length == points.length, "Wallets and points arrays should have the same length");

       for (uint256 i = 0; i < wallets.length; i++) {
           address wallet = wallets[i];
           uint256 point = points[i];

           require(wallet != address(0), "Invalid address");
           _pointsByAddresses[wallet] += point;
       }
    }

    // BCOwnerコントラクトアドレスを指定
    function setBCOwner(address _contractAddress) external onlyOwner {
        BCOwner = IBCOwner(_contractAddress);
    }

    // ポイント開始の時刻設定
    function setStartTime(uint256 _basetime) public onlyOwner {

        // 記録されている値を一旦消去
        delete basetime;

        // 値がミントセール開始6/11 12時（1686452400）より後であること
        require(_basetime >= 1686452400 , "cannot set before the release date.");

        // 必要なポイントの設定
        basetime = _basetime;
    }

    // 誤ってオーナーアドレスがゼロアドレスになることを回避する
    function renounceOwnership() public override onlyOwner {
        _transferOwnership(address(msg.sender));
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

interface IBCOwner{

    // BC Generative Owner関数を呼び出せるコントラクトアドレス
    function _allowedContracts(address _contract) external view returns (bool);
    // BC Generative トークンIdごとの所有ウォレットアドレス
    function _BCGenerativeHolders(uint256 _tokenId) external view returns (address);
    // BC Generative トークンIdごとの所有ウォレットアドレスの存在有無
    function _setHolders(uint256 _tokenId) external view returns (bool);

}