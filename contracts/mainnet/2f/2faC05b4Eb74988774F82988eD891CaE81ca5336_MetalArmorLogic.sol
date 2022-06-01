// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./AggregatorV3Interface.sol";

interface IERC721ChubbyAPE {
    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IERC1155MetalARMOR {
    function mintChubbyApeEquipment(address chubbyApeOwner)
        external
        returns (uint256[] memory ids);
}

interface IERC721MetalAPE {
    function ownerOf(uint256 tokenId) external view returns (address);

    function mintMetalApe(address _recipient) external returns (uint256 id);
}

interface IERC20Burn {
    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

/**
 * @title MetalArmorLogic
 */
contract MetalArmorLogic is Ownable {
    using SafeMath for uint256;
    using SafeMath for int256;
    using SafeMath for uint8;

    //Collector address
    address public EthCollector;

    //TotalSupply
    uint16 public TotalFreeSupply = 20000;

    IERC721ChubbyAPE public ChubbyAPE;
    IERC1155MetalARMOR public MetalARMOR;
    IERC721MetalAPE public MetalAPE;

    IERC20Burn public BOMT;
    IERC20Burn public WETH;
    IERC20Burn public USDT;

    /// Function Type
    uint8 public funcChubbyFreeMintArmor = 10;
    uint8 public funcPayMintArmorByMATIC = 11;
    uint8 public funcPayMintArmorByWETH = 12;
    uint8 public funcPayMintArmorByUSDT = 13;
    uint8 public funcPayMintArmorByBOMT = 14;

    ////////////////Signer related Start////////////////
    //RequestID
    mapping(uint256 => bool) public requestIDs;
    //Signer
    address public SignerAddress;
    ////////////////Signer related  End////////////////////

    //////////////// Chubby Free mint Start////////////////
    struct ChubbyFreeMintSetting {
        uint256 TotalSupply;
        uint256 Minted;
        uint256 Start;
        uint256 End;
        mapping(uint256 => uint16) mintedArmorCount;
        mapping(uint256 => uint16) mintedApeCount;
        // Create
        mapping(uint256 => uint16) exchangeArmorCount;
        mapping(uint256 => uint16) exchangeApeCount;
    }
    ChubbyFreeMintSetting _ChubbyFreeMintSetting;

    uint16 public exchangeArmorLimit = 2;
    uint16 public exchangeApeLimit = 2;

    function GetChubbyFreeMintSetting()
        public
        view
        returns (
            uint256 _TotalSupply,
            uint256 _Minted,
            uint256 _Start,
            uint256 _End
        )
    {
        return (
            _ChubbyFreeMintSetting.TotalSupply,
            _ChubbyFreeMintSetting.Minted,
            _ChubbyFreeMintSetting.Start,
            _ChubbyFreeMintSetting.End
        );
    }

    function GetChubbyFreeMintSetting_mintedCount(uint8 _type, uint256 _tokenID)
        public
        view
        returns (uint16 mintedCount)
    {
        if (_type == 1) {
            return _ChubbyFreeMintSetting.mintedArmorCount[_tokenID];
        } else {
            return _ChubbyFreeMintSetting.mintedApeCount[_tokenID];
        }
    }

    function GetChubbyFreeMintSetting_exchangeCount(
        uint8 _type,
        uint256 _tokenID
    ) public view returns (uint16 mintedCount) {
        if (_type == 1) {
            return _ChubbyFreeMintSetting.exchangeArmorCount[_tokenID];
        } else {
            return _ChubbyFreeMintSetting.exchangeApeCount[_tokenID];
        }
    }

    function setexchangeLimit(
        uint16 _exchangeArmorLimit,
        uint16 _exchangeApeLimit
    ) public onlyOwner {
        exchangeArmorLimit = _exchangeArmorLimit;
        exchangeApeLimit = _exchangeApeLimit;
    }

    //////////////// Chubby Free mint End////////////////

    //////////////// Pay mint　Start////////////////
    struct PayMintSetting {
        uint256 TotalSupply;
        uint256 Minted;
        uint256 Start;
        uint256 End;
        bool isSaleActive;
        mapping(uint256 => uint256) PayMintPrices;
        mapping(uint256 => uint256) BOMTPrices;
        mapping(address => uint16) mintedCount;
    }
    PayMintSetting _PayMintSetting;

    function GetPayMintSetting()
        public
        view
        returns (
            uint256 _TotalSupply,
            uint256 _Minted,
            uint256 _Start,
            uint256 _End,
            bool _isSaleActive
        )
    {
        return (
            _PayMintSetting.TotalSupply,
            _PayMintSetting.Minted,
            _PayMintSetting.Start,
            _PayMintSetting.End,
            _PayMintSetting.isSaleActive
        );
    }

    function GetPayMintSetting_mintedCount(address _address)
        public
        view
        returns (uint16 mintedCount)
    {
        return _PayMintSetting.mintedCount[_address];
    }

    function GetPayMintSalePrice(uint256 amount)
        public
        view
        returns (uint256 _price)
    {
        return _PayMintSetting.PayMintPrices[amount];
    }

    //Owner set Pay mint SaleActive
    function setPayMintSaleActive(bool _result) public onlyOwner {
        _PayMintSetting.isSaleActive = _result;
    }

    ////////////////　Pay mint End////////////////

    ////////////////FreeMint Start////////////////
    struct FreeMintSetting {
        uint256 TotalSupply; // 350
        uint256 Minted;
        uint256 Start;
        uint256 End;
        mapping(address => uint256) freeMintCount;
        mapping(address => bool) qualifiList;
    }
    FreeMintSetting _FreeMintSetting;

    function GetFreeMintSetting()
        public
        view
        returns (
            uint256 _TotalSupply,
            uint256 _Minted,
            uint256 _Start,
            uint256 _End
        )
    {
        return (
            _FreeMintSetting.TotalSupply,
            _FreeMintSetting.Minted,
            _FreeMintSetting.Start,
            _FreeMintSetting.End
        );
    }

    function GetFreeMintSetting_count(address _address)
        public
        view
        returns (uint256 count)
    {
        return _FreeMintSetting.freeMintCount[_address];
    }

    function GetFreeMintSetting_qualifiList(address _address)
        public
        view
        returns (bool qualifi)
    {
        return _FreeMintSetting.qualifiList[_address];
    }

    //Owner set free mint qualifi
    function setFreeMint_Qualifi(address[] memory _addressList, bool _result)
        public
        onlyOwner
    {
        require(_addressList.length > 0, "need address");
        for (uint16 i = 0; i < _addressList.length; i++) {
            _FreeMintSetting.qualifiList[_addressList[i]] = _result;
        }
    }

    ////////////////FreeMint End////////////////

    constructor() {
        // PreDefine ChubbyFreeMint
        _ChubbyFreeMintSetting.Minted = 0;
        _ChubbyFreeMintSetting.TotalSupply = 20000;

        //PreDefine PayMint
        _PayMintSetting.Minted = 0;
        _PayMintSetting.PayMintPrices[1] = 20000000000000000;
        _PayMintSetting.PayMintPrices[3] = 57000000000000000;
        _PayMintSetting.PayMintPrices[5] = 90000000000000000;
        _PayMintSetting.PayMintPrices[10] = 170000000000000000;
        _PayMintSetting.PayMintPrices[15] = 240000000000000000;
        _PayMintSetting.PayMintPrices[20] = 300000000000000000;

        _PayMintSetting.BOMTPrices[1] = 20000000000000000000;
        _PayMintSetting.BOMTPrices[3] = 57000000000000000000;
        _PayMintSetting.BOMTPrices[5] = 90000000000000000000;
        _PayMintSetting.BOMTPrices[10] = 170000000000000000000;
        _PayMintSetting.BOMTPrices[15] = 240000000000000000000;
        _PayMintSetting.BOMTPrices[20] = 300000000000000000000;

        //PreDefine FreeMint
        _FreeMintSetting.Minted = 0;
        _FreeMintSetting.TotalSupply = 350;
    }

    //Owner set Singer address
    function setSinger(address _signerAddress) public onlyOwner {
        SignerAddress = _signerAddress;
    }

    function verifySignData(bytes32 messageHash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == SignerAddress;
    }

    //Pubilc PayMint price setting
    function SetBundlePrice(
        uint8 _type,
        uint8[] memory _amount,
        uint256[] memory _price
    ) public onlyOwner {
        if (_type == 2) {
            for (uint16 i = 0; i < _amount.length; i++) {
                _PayMintSetting.PayMintPrices[_amount[i]] = _price[i];
            }
        }
        if (_type == 3) {
            for (uint16 i = 0; i < _amount.length; i++) {
                _PayMintSetting.BOMTPrices[_amount[i]] = _price[i];
            }
        }
    }

    //TotalSupply setting at each stage
    function SetTotalSupply(uint8 _type, uint16 _supply) public onlyOwner {
        //Type 1 is ChubbyFreeMint
        if (_type == 1) {
            _ChubbyFreeMintSetting.TotalSupply = _supply;
        }
    }

    //Period setting at each stage
    function SetPeriod(
        uint8 _type,
        uint256 _start,
        uint256 _end
    ) public onlyOwner {
        //Type 1 is ChubbyFreeMint
        if (_type == 1) {
            _ChubbyFreeMintSetting.Start = _start;
            _ChubbyFreeMintSetting.End = _end;
        }
        if (_type == 3) {
            _FreeMintSetting.Start = _start;
            _FreeMintSetting.End = _end;
        }
    }

    //SaleActive Check
    function isSaleActive(uint8 _tier) public view returns (bool) {
        if (
            _tier == 1 &&
            (block.timestamp > _ChubbyFreeMintSetting.Start &&
                _ChubbyFreeMintSetting.End > block.timestamp)
        ) {
            return true;
        }
        if (_tier == 2) {
            return _PayMintSetting.isSaleActive;
        }

        if (
            _tier == 3 &&
            (block.timestamp > _FreeMintSetting.Start &&
                _FreeMintSetting.End > block.timestamp)
        ) {
            return true;
        }

        return false;
    }

    function SetERC20(uint8 _type, address _address) public onlyOwner {
        if (_type == 1) {
            WETH = IERC20Burn(_address);
        }
        if (_type == 2) {
            USDT = IERC20Burn(_address);
        }
        if (_type == 3) {
            BOMT = IERC20Burn(_address);
        }
    }

    function SetInterfaceAddress(
        address _cAddress,
        address _aAddress,
        address _mAddress
    ) public onlyOwner {
        ChubbyAPE = IERC721ChubbyAPE(_cAddress);
        MetalARMOR = IERC1155MetalARMOR(_aAddress);
        MetalAPE = IERC721MetalAPE(_mAddress);
    }

    function SetCollector(uint8 _type, address _address) public onlyOwner {
        if (_type == 1) {
            EthCollector = _address;
        }
    }

    ///#region ChubbyFreeMint
    function ChubbyFreeMintArmor(
        uint256[] memory _tokenList,
        uint256 _amount,
        uint256 _value,
        uint8 _funcType,
        uint256 _requestID,
        bytes memory _signature
    ) public returns (uint256[][] memory idss) {
        require(isSaleActive(1), "ChubbyFreeMint is not ready"); // active check
        require(_amount != 0, "Amount count wrong");
        require(_tokenList.length == _amount, "amount wrong");
        require(
            _tokenList.length.add(_ChubbyFreeMintSetting.Minted) <=
                _ChubbyFreeMintSetting.TotalSupply,
            "TotalSupply is excced"
        ); //ChubbyFreeMint TotalSupply

        require(_funcType == funcChubbyFreeMintArmor, "funcType wrong");
        require(!requestIDs[_requestID], "RequestID check failed"); //RequestID check
        require(
            verifySignData(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        _amount,
                        _value,
                        _funcType,
                        _requestID
                    )
                ),
                _signature
            ),
            " verify "
        );

        for (uint16 i = 0; i < _tokenList.length; i++) {
            require(
                msg.sender == ChubbyAPE.ownerOf(_tokenList[i]),
                "Must own Chubby Ape token"
            ); // Chubby Ape owner check

            require(
                _ChubbyFreeMintSetting.exchangeArmorCount[_tokenList[i]] <
                    exchangeArmorLimit,
                "exchange armor check failed"
            ); //Limit check

            // Add exchange count
            _ChubbyFreeMintSetting.exchangeArmorCount[_tokenList[i]] =
                _ChubbyFreeMintSetting.exchangeArmorCount[_tokenList[i]] +
                1;
        }

        // Add Minted
        _ChubbyFreeMintSetting.Minted =
            _ChubbyFreeMintSetting.Minted +
            _amount.mul(6);

        requestIDs[_requestID] = true;

        return _BatchMint(_amount, msg.sender);
    }

    function getExchangeArmorCount(uint256 tokenID)
        public
        view
        returns (uint16 count)
    {
        return _ChubbyFreeMintSetting.exchangeArmorCount[tokenID];
    }

    ///#endregion ChubbyFreeMint

    ///#region PayMint
    //Pay Mint Armor By MATIC
    function PayMintArmorByMATIC(
        uint256 _amount,
        uint256 _value,
        uint8 _funcType,
        uint256 _requestID,
        bytes memory _signature
    ) public payable returns (uint256[][] memory idss) {
        require(isSaleActive(2), "sale is not ready");
        require(msg.value > 0 && _amount > 0); //Check _amount
        require(_amount != 0, "Amount count wrong");
        require(_funcType == funcPayMintArmorByMATIC, "funcType wrong");
        require(!requestIDs[_requestID], "RequestID check failed"); //RequestID check
        require(
            verifySignData(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        _amount,
                        _value,
                        _funcType,
                        _requestID
                    )
                ),
                _signature
            )
        );
        // Transfer
        require(_value == msg.value, "Value check failed"); //Value check
        //Transfer MATIC
        payable(EthCollector).call{value: msg.value}("");

        _PayMintSetting.Minted = _PayMintSetting.Minted + _amount.mul(6);
        requestIDs[_requestID] = true;

        return _BatchMint(_amount, msg.sender);
    }

    ///#endregion PayMint

    ///#region PayMint ERC20
    //Pay Mint Armor By ERC20
    function PayMintArmorByERC20(
        uint256 _amount,
        uint256 _value,
        uint8 _funcType,
        uint256 _requestID,
        bytes memory _signature
    ) public returns (uint256[][] memory idss) {
        require(isSaleActive(2), "sale is not ready");
        require(_amount != 0, "Amount count wrong");
        require(
            _funcType == funcPayMintArmorByWETH ||
                _funcType == funcPayMintArmorByUSDT ||
                _funcType == funcPayMintArmorByBOMT,
            "funcType wrong"
        );

        require(!requestIDs[_requestID], "RequestID check failed"); //RequestID check
        require(
            verifySignData(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        _amount,
                        _value,
                        _funcType,
                        _requestID
                    )
                ),
                _signature
            )
        );
        if (_funcType == funcPayMintArmorByWETH) {
            WETH.transferFrom(msg.sender, EthCollector, _value);
        }
        if (_funcType == funcPayMintArmorByUSDT) {
            USDT.transferFrom(msg.sender, EthCollector, _value);
        }
        if (_funcType == funcPayMintArmorByBOMT) {
            BOMT.transferFrom(msg.sender, EthCollector, _value);
        }

        _PayMintSetting.Minted = _PayMintSetting.Minted + _amount.mul(6);
        requestIDs[_requestID] = true;

        return _BatchMint(_amount, msg.sender);
    }

    ///#endregion PayMint ERC20

    ///#region FreeMint
    //Pubilc FreeMint
    function FreeMint(uint256 _amount) public returns (uint256[][] memory ids) {
        require(isSaleActive(3)); //FreeMint period check
        require(
            _amount.add(_FreeMintSetting.Minted) <=
                _FreeMintSetting.TotalSupply,
            "limit is exceed"
        ); //Check FreeMint TotalSupply

        require(
            _FreeMintSetting.qualifiList[msg.sender] == true,
            "Not in qualifiList"
        );

        //Mint Token
        _FreeMintSetting.Minted = _FreeMintSetting.Minted + _amount;
        _FreeMintSetting.freeMintCount[msg.sender] =
            _FreeMintSetting.freeMintCount[msg.sender] +
            _amount;

        return _BatchMint(uint256(_amount), msg.sender);
    }

    ///#endregion

    /***
    Mint 
     */
    function ReserveMint(address _recipient, uint16 _amount)
        public
        onlyOwner
        returns (uint256[][] memory ids)
    {
        return _BatchMint(_amount, _recipient);
    }

    // Mint Armor
    function _BatchMint(uint256 numTokens, address recipient)
        internal
        returns (uint256[][] memory ids)
    {
        ids = new uint256[][](numTokens);

        for (uint16 i = 0; i < numTokens; i++) {
            // Mint Armor
            ids[i] = _ArmorMint(recipient);
        }
        return ids;
    }

    function _ArmorMint(address recipient)
        internal
        returns (uint256[] memory ids)
    {
        return IERC1155MetalARMOR(MetalARMOR).mintChubbyApeEquipment(recipient);
    }

    // Mint Metal Ape
    function _MetalApeMint(address recipient) internal returns (uint256 id) {
        return IERC721MetalAPE(MetalAPE).mintMetalApe(recipient);
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65);
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function getMessageHash(
        address _to,
        uint256 _amount,
        uint256 _value,
        uint8 _funcType,
        uint256 _requestID
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_to, _amount, _value, _funcType, _requestID)
            );
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        /*Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg*/
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId) external view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

    function latestRoundData() external view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}