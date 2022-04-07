/**
 *Submitted for verification at polygonscan.com on 2022-04-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

// import "../utils/Context.sol";
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// import "@openzeppelin/contracts/access/Ownable.sol";
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


// import "./Common/ICardToken.sol";
interface ICardToken {
    //------------------------------
    // event
    //------------------------------
    event CardMinted( address indexed owner, uint256 tokenId, uint256 setId, uint256 themeId, uint256 cardId, uint256 serial );

    //------------------------------
    // 関数
    //------------------------------
    function mintToken( address owner, uint256 setId, uint256 themeId, uint256 cardId, uint256 serial ) external returns (uint256);
}


// import "./Common/IArtToken.sol";
interface IArtToken {
    //------------------------------
    // event
    //------------------------------
    event ArtMinted( address indexed owner, uint256 tokenId, uint256 setId, uint256 artId );

    //------------------------------
    // 関数
    //------------------------------
    function mintToken( address owner, uint256 setId, uint256 artId ) external returns (uint256);
}


// import "./Common/LibRand.sol";
library LibRand {
    //----------------------------------------------------------------------------------------------------------------------
    // 乱数のシードの生成：[rand32]への初期値となる値を作成する
    //----------------------------------------------------------------------------------------------------------------------
    // [rand32]が繰り返し呼ばれる流れを複数実装する場合、[seed]値を変えることで、同じ[base]値から異なる初期値を取りだせる
    //（※例えば、[rand32]を複数呼ぶ関数をコールする際、同じ初期値を使ってしまうと関数の呼び先で同じ乱数が生成されることになるので注意すること）
    //----------------------------------------------------------------------------------------------------------------------
    function randInitial32WithBase( uint256 base, uint8 seed ) internal pure returns (uint32) {
        // ベース値から[32]ビット抽出する（※[seed]の値により取り出し位置を変える）
        // [seed]の値によってシフトされるビットは最大で[13*7+37=128]となる（※[uint160=address]の最上位32ビットまでを想定）
        return( uint32( base + seed + (base >> (13*(seed%8) + (seed%38))) ) );
    }

    //----------------------------------------------------------
    // 乱数の作成：
    //----------------------------------------------------------
    function createRand32( uint256 base0, uint8 seed ) internal view returns(uint32) {
        // base値の算出
        uint256 base1 = uint256( uint160(msg.sender) ); // addressを流用
        uint256 base = (base0 ^ base1 );

        uint32 initial = randInitial32WithBase( base, seed );
        return( updateRand32( initial ) );
    }

    //----------------------------------------------------------
    // 乱数の更新：返値を次回の入力に使うことで乱数の生成を繰り返す想定
    //----------------------------------------------------------
    function updateRand32( uint32 val ) internal pure returns (uint32) {
        val ^= (val >> 13);
        val ^= (val << 17);
        val ^= (val << 15);

        return( val );
    }
}


//-----------------------------------
// PackVender
//-----------------------------------
contract PackVender is Ownable {
    //--------------------------------------
    // 定数
    //--------------------------------------
    // 管理アカウント（本番環境）
    address constant private OWNER_ADDRESS = 0x39BE5eb48C4A37831A5e8DF1763a9298a9dAaE8c;
    address constant private CONTROLLER_ADDRESS = 0x7Ffe8995f1Bdfd58A0F9cC5162B246DADB974a5B;

    // カードの数
    uint256 constant private TRUMP_CARD_NUM_IN_THEME = 13;      // テーマ内のトランプのカード数（A 2 3 4 5 6 7 8 9 10 J Q K）
    uint256 constant private TRUMP_CARD_THEME_NUM_IN_SET = 4;   // セット内のテーマ数(スペード、ハート、ダイヤ、クローバー)
    uint256 constant private TRUMP_CARD_NUM_IN_SET = 52;        // セット内のトランプのカード数（13 x 4）
    uint256 constant private JOKER_CARD_NUM_IN_SET = 2;         // セット内のジョーカーのカード数（2）
    uint256 constant private CARD_NUM_IN_SET = 54;              // セット内のカード数（52 + 2）
    uint256 constant private PACK_IN_SERIAL = 18;               // １シリアルに対するパック数（３枚１パックなので１シリアルにつき１８パックできる）

    // テーマ参照先
    uint256 constant private THEME_A_IN_SET = 0;                // カード番号１〜１３のテーマID(スペード相当のテーマ)
    uint256 constant private THEME_B_IN_SET = 1;                // カード番号１４〜２６のテーマID(ハート相当のテーマ)
    uint256 constant private THEME_C_IN_SET = 2;                // カード番号２７〜３９のテーマID(ダイヤ相当のテーマ)
    uint256 constant private THEME_D_IN_SET = 3;                // カード番号４０〜５２のテーマID(クローバー相当のテーマ)
    uint256 constant private THEME_J0_IN_SET = 4;               // カード番号５３のテーマID(ジョーカーＡのテーマ)
    uint256 constant private THEME_J1_IN_SET = 5;               // カード番号５４のテーマID(ジョーカーＢのテーマ)
    uint256 constant private THEME_NUM_IN_SET = 6;              // １セット内のテーマ数

    // 発行数管理用
    uint256 constant private DATA_BIT_NUM = 4;                  // １データのビット数（4bit)（シリアル番号１５まで管理可能）
    uint256 constant private DATA_BIT_MASK = 0xF;               // １データのマスク
    uint256 constant private BIT_SHIFT_FOR_NORMAL = 0;          // ノーマルカードデータのビット位置（ノーマルカードは数札＝２、３、４、５、６、７、８、９、１０）
    uint256 constant private DATA_NUM_IN_NORMAL = 36;           // ノーマルカードの数（4x9）
    uint256 constant private BIT_SHIFT_FOR_RARE = 144;          // レアカードデータのビット位置（レアカードは絵札＝Ａ、Ｊ、Ｑ、Ｋ、JOKER(0)、JOKER(1)）
    uint256 constant private DATA_NUM_IN_RARE = 18;             // レアカードの数（4x4 + 2）
    uint256 constant private BIT_SHIFT_FOR_LUCKY = 216;         // ラッキーカードデータのビット位置（ラッキーカードは８枚）
    uint256 constant private DATA_NUM_IN_LUCKY = 8;             // ラッキーカードの数（8）
    //uint256 constant private BIT_SHIFT_FOR_LAST = 248;          // ラストワンカードのビット位置（最後のパックに封入されるので管理データは不要）
    //uint256 constant private DATA_NUM_IN_LAST = 2;              // ラストワンのカードの数（2）

    //--------------------------------------
    // 管理データ
    //--------------------------------------
    address private _controller;

    // 扱うNFTのコントラクト
    address private _card_contract;     // ICardToken
    address private _art_contract;      // IArtToken

    // 管理マップ
    mapping( uint256 => bool ) private _map_valid;      // セットの有効性
    mapping( uint256 => uint256 ) private _map_data_id; // setId → dataId 参照用

    // 各種データ(dataIdでアクセス)
    uint256[THEME_NUM_IN_SET][] private _arr_arr_theme;    // テーマID配列
    uint256[] private _arr_max_serial;      // シリアル番号１から何番まで売るのか？（10を指定した場合、180パック売ることになる）
    uint256[] private _arr_sold_pack;       // 販売済みパック数
    uint256[] private _arr_price;           // 販売価格
    bool[] private _arr_on_sale;            // 販売中か？
    uint256[] private _arr_status;          // ステータス（各カードの発行数）

    //-----------------------------------------
    // [modifier] コントローラーからのみ呼び出せる
    //-----------------------------------------
    modifier onlyController() {
        require( controller() == msg.sender, "caller is not the controller" );
        _;
    }

    //--------------------------------------
    // コンストラクタ
    //--------------------------------------
    constructor() Ownable() {
        transferOwnership( OWNER_ADDRESS );
        _controller = CONTROLLER_ADDRESS;        
    }

    //-----------------------------------------
    // [public] コントローラー
    //-----------------------------------------
    function controller() public view returns (address) { return( _controller ); }

    //-----------------------------------------
    // [external/onlyOwner] コントローラーの設定
    //-----------------------------------------
    function setController( address __controller ) external onlyOwner {
        _controller = __controller;
    }

    //---------------------------------------
    // [public] 管理情報確認
    //---------------------------------------
    function cardContract() public view returns (address) { return( _card_contract ); }
    function artContract() public view returns (address) { return( _art_contract ); }

    //---------------------------------------
    // [external/onlyController] 管理情報設定
    //---------------------------------------
    function setCardContract( address __contract ) external onlyController { _card_contract = __contract; }
    function setArtContract( address __contract ) external onlyController { _art_contract = __contract; }

    //---------------------------------------
    // [external/onlyController] セット登録
    //---------------------------------------
    function registerSet( uint256 setId, uint256[THEME_NUM_IN_SET] calldata themes, uint256 maxSerial, uint256 price ) external onlyController {
        require( setId > 0, "invalid setId" );
        require( ! _map_valid[setId], "already registered" );
        for( uint256 i=0; i<THEME_NUM_IN_SET; i++ ){
            require( themes[i] > 0, "invalid themes" );
        }
        require( maxSerial > 0 && maxSerial <= DATA_BIT_MASK, "invalid maxSerial" ); // シリアル管理ビット数に収まらなければダメ

        // データID割り当て
        uint256 dataId = _arr_arr_theme.length;
        _map_data_id[setId] = dataId;

        // 登録
        _arr_arr_theme.push( themes );
        _arr_max_serial.push( maxSerial );
        _arr_sold_pack.push( 0 );
        _arr_price.push( price );
        _arr_on_sale.push( false );
        _arr_status.push( 0 );

        // 有効化
        _map_valid[setId] = true;
    }

    //---------------------------------------
    // [external/onlyController] セット解除
    //---------------------------------------
    function unregisterSet( uint256 setId ) external onlyController {
        require( _map_valid[setId], "not registered" );

        delete _map_valid[setId];
    }

    //---------------------------------------
    // [public] セットが有効か？
    //---------------------------------------
    function isSetValid( uint256 setId ) public view returns (bool) {
        return( _map_valid[setId] );
    }

    //---------------------------------------
    // [public] セット情報確認
    //---------------------------------------
    // テーマID
    function getSetThemes( uint256 setId ) public view returns (uint256[THEME_NUM_IN_SET] memory) {
        if( isSetValid( setId ) ){
            return( _arr_arr_theme[_map_data_id[setId]] );
        }
        uint256[THEME_NUM_IN_SET] memory empty;
        return( empty );
    }

    // 最大シリアル
    function getSetMaxSerial( uint256 setId ) public view returns (uint256) {
        if( isSetValid( setId ) ){
            return( _arr_max_serial[_map_data_id[setId]] );
        }
        return( 0 );
    }

    // 販売済みのパック数
    function getSetSoldPack( uint256 setId ) public view returns (uint256) {
        if( isSetValid( setId ) ){
            return( _arr_sold_pack[_map_data_id[setId]] );
        }
        return( 0 );
    }

    // 販売パック数
    function getSetMaxPack( uint256 setId ) public view returns (uint256) {
        if( isSetValid( setId ) ){
            return( PACK_IN_SERIAL * _arr_max_serial[_map_data_id[setId]] );
        }
        return( 0 );
    }

    // 価格
    function getSetPrice( uint256 setId ) public view returns (uint256) {
        if( isSetValid( setId ) ){
            return( _arr_price[_map_data_id[setId]] );
        }
        return( 0 );
    }

    // 販売中か？
    function isSetOnSale( uint256 setId ) public view returns (bool) {
        if( isSetValid( setId ) ){
            return( _arr_on_sale[_map_data_id[setId]] );
        }
        return( false );
    }

    // ステータスデータ
    function getStatus( uint256 setId ) public view returns (uint256) {
        if( isSetValid( setId ) ){
            return( _arr_status[_map_data_id[setId]] );
        }
        return( 0 );
    }

    // ステータスデータ（個別）
    function getStatusAt( uint256 setId, uint256 at ) public view returns (uint256) {
        if( isSetValid( setId ) ){
            uint256 status = _arr_status[_map_data_id[setId]];
            status >>= at * DATA_BIT_NUM;
            return( status & DATA_BIT_MASK );
        }
        return( 0 );
    }

    //---------------------------------------
    // [external 販売情報取得
    //---------------------------------------
    function getSaleInfo( uint256 setId ) external view returns (uint256[5] memory) {
        uint256[5] memory result;

        if( isSetValid( setId) ){
            uint256 dataId = _map_data_id[setId];
            result[0] = 1;                                          // 有効か？
            result[1] = (_arr_on_sale[dataId])? 1: 0;               // 販売中か?
            result[2] = PACK_IN_SERIAL * _arr_max_serial[dataId];   // 販売パック数
            result[3] = _arr_sold_pack[dataId];                     // 販売済みのパック数
            result[4] = _arr_price[dataId];                         // 価格 
        }

        return( result );
    }

    //--------------------------------------------------------------------------------------------------
    // [external/onlyController] セット情報設定（整合性が崩れるのでテーマIDや最大シリアルの変更は不可＝必要なら再登録する）
    //--------------------------------------------------------------------------------------------------
    // 価格
    function setSetPrice( uint256 setId, uint256 price ) external onlyController {
        require( isSetValid( setId ), "unregistered set" );
        _arr_price[_map_data_id[setId]] = price;
    }

    // 販売中か？
    function setSetOnSale( uint256 setId, bool flag ) external onlyController {
        require( isSetValid( setId ), "unregistered set" );
        _arr_on_sale[_map_data_id[setId]] = flag;
    }

    //---------------------------------------
    // [external/payable] パックの購入
    //---------------------------------------
    function buyPack( uint256 setId ) external payable {
        // セットが有効か？
        require( isSetValid( setId ), "unregistered set" );

        // 販売中か？
        require( isSetOnSale( setId ), "not on sale" );

        // 入金は有効か？
        require( getSetPrice( setId ) <= msg.value, "insufficient value" );

        // 残りはあるか？
        uint256 max = getSetMaxPack( setId );
        uint256 sold = getSetSoldPack( setId );
        require( sold < max, "sold out"  );

        uint256 remain = max - sold;

        //------------------------
        // ノーマルカードの排出（２枚）
        //------------------------
        // 抽選（１枚目）
        uint32 randVal = LibRand.createRand32( block.timestamp + remain, uint8(block.number) );
        _drawNormal( msg.sender, setId, 2*remain, randVal );

        // 抽選（２枚目）
        randVal = LibRand.updateRand32( randVal );
        _drawNormal( msg.sender, setId, 2*remain-1, randVal );

        //------------------------
        // レアカードの排出（１枚）
        //------------------------
        // 抽選
        randVal = LibRand.updateRand32( randVal );
        _drawRare( msg.sender, setId, remain, randVal );

        //------------------------
        // ラッキーカードの排出
        //------------------------
        // 抽選
        randVal = LibRand.updateRand32( randVal );
        _drawLucky( msg.sender, setId, remain, randVal );

        //------------------------
        // ラストワンの排出
        //------------------------
        if( remain == 1 ){
            _drawLastOne( msg.sender, setId );
        }

        // 販売数インクリメント
        _arr_sold_pack[_map_data_id[setId]]++;
    }

    //---------------------------------------
    // [internal] ノーマルカードの排出
    //---------------------------------------
    function _drawNormal( address target, uint256 setId, uint256 remain, uint32 randVal ) internal {
        uint256 status = _arr_status[_map_data_id[setId]];
        uint256 maxSerial = _arr_max_serial[_map_data_id[setId]];

        // 抽選
        uint256 at = uint256(randVal) % remain;
        uint256 dataAt = 0;
        uint256 cardId = 0;
        uint256 themeId = 0;        
        uint256 serial = 0;
        for( uint256 i=0; i<DATA_NUM_IN_NORMAL; i++ ){
            serial = (status >> (BIT_SHIFT_FOR_NORMAL+DATA_BIT_NUM*i)) & DATA_BIT_MASK;
            if( serial < maxSerial ){
                uint256 rest = maxSerial - serial;
                if( at < rest ){
                    dataAt = i;

                    // 2 〜 10
                    cardId = 2 + (dataAt%9) + 13*(dataAt/9);
                    themeId = _arr_arr_theme[_map_data_id[setId]][dataAt/9];
                    break;
                }
                at -= rest;
            }
        }

        // この時点でcardIdが０なのはおかしい
        require( cardId != 0, "invalid cardId" );

        // シリアルのインクリメント（パック販売は１はじめ）
        serial++;

        // 排出
        ICardToken iCard = ICardToken(_card_contract);
        iCard.mintToken( target, setId, themeId, cardId, serial );

        // ステータスの更新（排出したカードのシリアルのインクリメント）
        status &= ~(DATA_BIT_MASK << (BIT_SHIFT_FOR_NORMAL+DATA_BIT_NUM*dataAt));
        status |= serial << (BIT_SHIFT_FOR_NORMAL+DATA_BIT_NUM*dataAt);
        _arr_status[_map_data_id[setId]] = status;
    }

    //---------------------------------------
    // [internal] レアカードの排出
    //---------------------------------------
    function _drawRare( address target, uint256 setId, uint256 remain, uint32 randVal ) internal {
        uint256 status = _arr_status[_map_data_id[setId]];
        uint256 maxSerial = _arr_max_serial[_map_data_id[setId]];

        // 抽選
        uint256 at = uint256(randVal) % remain;
        uint256 dataAt = 0;
        uint256 cardId = 0;
        uint256 themeId = 0;        
        uint256 serial = 0;
        for( uint256 i=0; i<DATA_NUM_IN_RARE; i++ ){
            serial = (status >> (BIT_SHIFT_FOR_RARE+DATA_BIT_NUM*i)) & DATA_BIT_MASK;
            if( serial < maxSerial ){
                uint256 rest = maxSerial - serial;
                if( at < rest ){
                    dataAt = i;

                    // JOKER(1)
                    if( dataAt == 17 ){
                        cardId = 54;
                        themeId = _arr_arr_theme[_map_data_id[setId]][THEME_J1_IN_SET];
                    }
                    // JOKER(0)
                    else if( dataAt == 16 ){
                        cardId = 53;
                        themeId = _arr_arr_theme[_map_data_id[setId]][THEME_J0_IN_SET];
                    }
                    // 絵札
                    else{
                        // A
                        if( (dataAt%4) == 0 ){
                            cardId = 1 + 13*(dataAt/4);
                        }
                        // JQK
                        else{
                            cardId = 11 + 13*(dataAt/4) + ((dataAt%4)-1);
                        }
                        themeId = _arr_arr_theme[_map_data_id[setId]][dataAt/4];
                    }
                    break;
                }
                at -= rest;
            }
        }

        // この時点でcardIdが０なのはおかしい
        require( cardId != 0, "invalid cardId" );

        // シリアルのインクリメント（パック販売は１はじめ）
        serial++;

        // 排出
        ICardToken iCard = ICardToken(_card_contract);
        iCard.mintToken( target, setId, themeId, cardId, serial );

        // ステータスの更新（排出したカードのシリアルのインクリメント）
        status &= ~(DATA_BIT_MASK << (BIT_SHIFT_FOR_RARE+DATA_BIT_NUM*dataAt));
        status |= serial << (BIT_SHIFT_FOR_RARE+DATA_BIT_NUM*dataAt);
        _arr_status[_map_data_id[setId]] = status;
    }

    //---------------------------------------
    // [internal] ラッキーカードの排出
    //---------------------------------------
    function _drawLucky( address target, uint256 setId, uint256 remain, uint32 randVal ) internal {
        uint256 status = _arr_status[_map_data_id[setId]];

        // ラッキーカードの残りを算出（ラッキーカードは１種１枚）
        uint256 rest;
        for( uint256 i=0; i<DATA_NUM_IN_LUCKY; i++ ){
            // 未排出なら残数インクリメント
            uint256 serial = (status >> (BIT_SHIFT_FOR_LUCKY+DATA_BIT_NUM*i)) & DATA_BIT_MASK;
            if( serial == 0 ){
                rest++;
            }
        }

        // 抽選（残りのラッキーカードとパック数に応じて確率が変わる）
        uint256 at = uint256(randVal) % remain;
        if( at >= rest ){
            return;
        }

        // ここまできたら当選
        uint256 dataAt = 0;
        uint256 artId = 0;
        for( uint256 i=0; i<DATA_NUM_IN_LUCKY; i++ ){
            // 未排出なら排出チェック
            uint256 serial = (status >> (BIT_SHIFT_FOR_LUCKY+DATA_BIT_NUM*i)) & DATA_BIT_MASK;
            if( serial == 0 ){
                if( at <= 0 ){
                    dataAt = i;
                    artId = dataAt + 1; // アートIDは１はじめの連番
                    break;
                }
                at--;
            }
        }

        // この時点でartIdが０なのはおかしい
        require( artId != 0, "invalid artId" );

        // 排出
        IArtToken iArt = IArtToken(_art_contract);
        iArt.mintToken( target, setId, artId );

        // ステータスの更新（排出したアートのシリアルを１に）
        status |= 1 << (BIT_SHIFT_FOR_LUCKY+DATA_BIT_NUM*dataAt);
        _arr_status[_map_data_id[setId]] = status;
    }

    //---------------------------------------
    // [internal] ラストワンの排出
    //---------------------------------------
    function _drawLastOne( address target, uint256 setId ) internal {
        ICardToken iCard = ICardToken(_card_contract);
        uint256[THEME_NUM_IN_SET] memory themes = getSetThemes( setId );

        // JOKER0のテーマが有効なら
        if( themes[THEME_J0_IN_SET] > 0 ){
            iCard.mintToken( target, setId, themes[THEME_J0_IN_SET], 53, 0 );   // 53 が JOKER0（シリアル番号は０）
        }

        // JOKER1のテーマが有効なら
        if( themes[THEME_J1_IN_SET] > 0 ){
            iCard.mintToken( target, setId, themes[THEME_J1_IN_SET], 54, 0 );   // 54 が JOKER1（シリアル番号は０）
        }
    }

    //---------------------------------------
    // [external/onlyController] 直接販売準備
    //---------------------------------------
    function reserveForSale( uint256 setId ) external onlyController {
        require( isSetValid( setId ), "unregistered set" );

        ICardToken iCard = ICardToken(_card_contract);
        uint256[THEME_NUM_IN_SET] memory themes = getSetThemes( setId );

        // シリアル番号０のトランプをオーナーに発行する（ジョーカーはラストワン賞にわりあてられる）
        for( uint256 i=0; i<TRUMP_CARD_THEME_NUM_IN_SET; i++ ){
            for( uint256 j=0; j<TRUMP_CARD_NUM_IN_THEME; j++ ){
                uint256 cardId = 1 + i*TRUMP_CARD_NUM_IN_THEME + j;         // カードIDは１はじめ
                iCard.mintToken( owner(), setId, themes[i], cardId, 0 );
            }
        }
    }

    //--------------------------------------------------------
    // [external] 残高の確認
    //--------------------------------------------------------
    function checkBalance() external view returns (uint256) {
        return( address(this).balance );
    }

    //--------------------------------------------------------
    // [external/onlyOwner] 引き出し
    //--------------------------------------------------------
    function withdraw( uint256 amount ) external onlyOwner {
        require( amount <= address(this).balance, "insufficient balance" );

        address payable target = payable( msg.sender );
        target.transfer( amount );
    }

}