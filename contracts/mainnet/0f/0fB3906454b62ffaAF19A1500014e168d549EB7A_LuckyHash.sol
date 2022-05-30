/**
 *Submitted for verification at polygonscan.com on 2022-05-30
*/

// SPDX-License-Identifier: BSL

pragma solidity 0.8.13;

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

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () {
      address msgSender = _msgSender();
      _owner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);
    }

    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns (address) {
      return _owner;
    }

    
    modifier onlyOwner() {
      require(_owner == _msgSender(), "Ownable: caller is not the owner");
      _;
    }

    function renounceOwnership() public onlyOwner {
      emit OwnershipTransferred(_owner, address(0));
      _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
      _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
      require(newOwner != address(0), "Ownable: new owner is the zero address");
      emit OwnershipTransferred(_owner, newOwner);
      _owner = newOwner;
    }
}

contract LuckyHash is Context, Ownable {
    using SafeMath for uint256;

    address public devAddress;
    IERC20 public erc20;

    mapping (address=>uint256) public userUnpaid;
    mapping (uint8=>mapping(address=>uint256[])) public history;
    mapping (uint32=>bytes32) public blockhashes;
    uint32[] public blocknumbers;

    uint32 public oddsHiLo = 190;
    uint32 public oddsEvenOdd = 190;
    uint32 public oddsLott = 1500;
    uint32[] public oddsSlot = [1200, 2000, 2500, 7000, 15000, 30000, 50000];

    mapping (address=>uint32[]) public superHiloBlocks;

    event GameResult(address indexed adr, bytes32 _hash, uint8 num, uint256 amount);

    constructor(address token) {
        devAddress = msg.sender;
        erc20 = IERC20(token);
    }

    function getBalance() public view returns(uint256) {
        return erc20.balanceOf(address(this));
    }

    function getMyBalance() external view returns(uint256) {
        return userUnpaid[msg.sender];
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(erc20.balanceOf(address(this)) >= amount, "E");
        require(erc20.transfer(msg.sender, amount));
    }

    function setOdds(uint32 hilo, uint32 evenodd, uint32 lott) external onlyOwner {
        require(hilo > 100 && evenodd > 100 && lott > 100 && hilo < 200 && evenodd < 200 && lott < 1600);
        oddsHiLo = hilo;
        oddsEvenOdd = evenodd;
        oddsLott = lott;
    }

    function saveBlockNum(uint32 num) private {
        bool saved = false;
        for (uint32 i=0; i<blocknumbers.length; i++) {
            if (blocknumbers[i] == 0) {
                blocknumbers[i] = num;
                saved = true;
                break;
            }
        }
        if (!saved) {
            blocknumbers.push(num);
        }
    }

    function saveRecord(uint8 game, address adr, uint256 choice, uint256 bet) internal {
        // 4 bytes blocktime | 4 bytes blocknum | 8 bytes choice | 12 bytes win amount | 4 bytes result
        uint256 rec = ((block.timestamp << 224) & 0xffffffff00000000000000000000000000000000000000000000000000000000)
                    | (((block.number+1) << 192) & 0x00000000ffffffff000000000000000000000000000000000000000000000000)
                    | ((choice << 128) & 0x0000000000000000ffffffffffffffff00000000000000000000000000000000)
                    | ((bet << 32) & 0x00000000000000000000000000000000ffffffffffffffffffffffff00000000);
        history[game][adr].push(rec);
        saveBlockNum(uint32(block.number+1));
    }

    function getRecord(uint256 rec) private pure returns (uint32 blocknum, uint256 choice, uint256 bet, uint256 result) {
        blocknum = uint32((rec >> 192) & 0xffffffff);
        choice = (rec >> 128) & 0xffffffffffffffff;
        bet = (rec >> 32) & 0xffffffffffffffffffffffff;
        result = rec & 0xffffffff;
    }

    function updateRecord(uint8 game, address adr, uint256 idx, uint256 amount) internal {
        uint256 rec = history[game][adr][idx];
        rec = (rec & 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000) 
            | ((amount>0 ? 1:2) & 0xffffffff);

        if (amount > 0) {
            rec = (rec & 0xffffffffffffffffffffffffffffffff000000000000000000000000ffffffff)
            | ((amount << 32) & 0x00000000000000000000000000000000ffffffffffffffffffffffff00000000);
        }
        history[game][adr][idx] = rec;
    }

    function getBlockHash(uint32 blocknum) public returns (bytes32) {
        for (uint32 i=0; i<blocknumbers.length; i++) {
            if (blocknumbers[i] != 0) {
                bytes32 _hash = blockhash(blocknumbers[i]);
                if (_hash != 0) {
                    blockhashes[blocknumbers[i]] = _hash;
                    blocknumbers[i] = 0;
                }
            }
        }

        bytes32 hash = blockhashes[blocknum];
        if (hash == 0) {
            hash = blockhash(blocknum);
            if (hash == 0) return 0;
            blockhashes[blocknum] = hash;
        }

        return hash;
    }

    function luckyResult(uint256 rec) public {
        calcHiLo(rec);
        calcEvenOdd(rec);
        calcLott(rec);
        calcSlot(rec);
        superCashOut();
    }
    
    function takeBetAmount(uint256 amount) internal {
        require(amount >= 10*10**18 && amount <= 10000*10**18, "E");
        uint256 fee = SafeMath.mul(amount, 5).div(200);
        require(erc20.transferFrom(address(msg.sender), devAddress, fee));
        require(erc20.transferFrom(address(msg.sender), address(this), amount.sub(fee)));
    }

    function rewardWinner(address adr, uint256 amount) private {
        if (erc20.balanceOf(address(this)) < amount) {
                userUnpaid[adr] = userUnpaid[adr].add(amount);
        } else {
            require(erc20.transfer(adr, amount));
            if (userUnpaid[adr] > 0 && erc20.balanceOf(address(this)) >= userUnpaid[adr]) {
                uint unpaid = userUnpaid[adr];
                userUnpaid[adr] = 0;
                require(erc20.transfer(adr, unpaid));
            }
        }
    }

    function checkRecord(uint256[] memory recs, uint256 rec) private pure returns(bool, uint256) {
        uint len = recs.length > 20 ? recs.length-20 : recs.length;
        for(uint i=recs.length-len; i<recs.length; i++) {
            if (recs[i] == rec) {
                return (true, i);
            }
        }

        return (false, recs.length-1);
    }

    function verifyRecord(uint8 game, uint256 rec) private view returns(uint256, uint256) {
        uint256[] storage recs = history[game][msg.sender];
        if (recs.length == 0) return (0, 0);
        uint256 recIdx = recs.length-1;
        if (rec == 0) {
            rec = recs[recIdx];
        } else {
            bool exist;
            (exist,  recIdx) = checkRecord(recs, rec);
            if (!exist) return (0, 0);
        }

        return (recIdx, rec);
    }

    function calcHiLo(uint256 rec) internal {
        uint256 recIdx;
        (recIdx, rec) = verifyRecord(0, rec);
        if (rec == 0) return;
        (uint32 blocknum, uint256 choice, uint256 bet, uint256 result) = getRecord(rec);
        if (result > 0) return;
        bytes32 hash = getBlockHash(blocknum);
        if (hash == 0) return;
        uint256 amount;
        if ((choice == 0 && (uint8(hash[31]) & 0x0F) <= 7)
            || (choice == 1 && (uint8(hash[31]) & 0x0F) > 7)) { // win
            amount = SafeMath.mul(bet, oddsHiLo).div(100);
            rewardWinner(msg.sender, amount);
        }
        updateRecord(0, msg.sender, recIdx, amount);
        emit GameResult(msg.sender, hash, uint8(hash[31])&0x0F, amount);
    }

    function luckyHiLo(bool hi, uint256 amount) external {
        takeBetAmount(amount);
        luckyResult(0);
        saveRecord(0, msg.sender, hi ? 1 : 0, amount);
    }

    function saveSuperHiloRecord(address adr, uint32 blocknum, uint256 bet) internal {
        // 4 bytes blocktime | 4 bytes blocknum | 8 bytes choice | 6 bytes win amount | 6 bytes bet amount | 4 bytes result
        uint256 rec = ((block.timestamp << 224) & 0xffffffff00000000000000000000000000000000000000000000000000000000)
                    | ((uint256(blocknum) << 192) & 0x00000000ffffffff000000000000000000000000000000000000000000000000);
        if (bet > 0) {
            if (bet >= 10**18) { // only use decimal 6 to save
                bet = bet.div(10**12);
            }
            rec = rec | ((bet << 32) & 0x000000000000000000000000000000000000000000000ffffffffffff00000000)
                      | ((bet << 80) & 0x000000000000000000000000000000000ffffffffffff00000000000000000000);
        }
        history[3][adr].push(rec);
    }

    function saveSuperHiloBlocks(address adr, bool clear, uint32 blocknum) private {
        bool saved = false;
        uint32[] storage blocks = superHiloBlocks[adr];

        if (clear) {
            for (uint32 i=0; i<blocks.length; i++) {
                blocks[i] = 0;
            }
        }
        
        for (uint32 i=0; i<blocks.length; i++) {
            if (blocks[i] == 0) {
                blocks[i] = blocknum;
                saved = true;
                break;
            }
        }
        if (!saved) {
            blocks.push(blocknum);
        }

        saveBlockNum(blocknum);
    }

    function updateSuperHiloRecord(address adr, uint32 result, uint256 amount) internal {
        uint256 recIdx = history[3][adr].length-1;
        uint256 rec = history[3][adr][recIdx];
        if (result > 0) {
            rec = (rec & 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000) 
            | (result & 0xffffffff);
        }
        if (amount > 0) {
            rec = (rec & 0xffffffffffffffffffffffffffffffff000000000000ffffffffffffffffffff)
            | ((amount << 80) & 0x00000000000000000000000000000000ffffffffffff00000000000000000000);
        }

        uint32[] storage blocks = superHiloBlocks[adr];
        uint256 choice;
        for (uint32 i=0; i<blocks.length; i++) {
            if (blocks[i] != 0) {
                bytes32 hash = getBlockHash(blocks[i]);
                uint8 num = uint8(hash[31]) & 0x0F;
                choice = choice | ((uint64(num) << (60-i*4)) & (0xf << (60-i*4)));
            }
        }
        rec = (rec & 0xffffffffffffffff0000000000000000ffffffffffffffffffffffffffffffff) 
            | ((choice << 128) & 0x0000000000000000ffffffffffffffff00000000000000000000000000000000);
        history[3][adr][recIdx] = rec;
    }

    function getSuperHiloStepCount() public view returns(uint32) {
        uint32[] memory blocks = superHiloBlocks[msg.sender];
        for (uint32 i=0; i<blocks.length; i++) {
            if (blocks[i] == 0) {
                return i;
            }
        }
        return uint32(blocks.length);
    }

    function getSuperHiloBlocks() public view returns(uint32[] memory _blocks, bytes32[] memory _hashs) {
        uint32[] memory blocks = superHiloBlocks[msg.sender];
        _blocks = new uint32[](blocks.length);
        _hashs = new bytes32[](blocks.length);
        for (uint i=0; i<blocks.length; i++) {
            if (blocks[i] == 0)
                break;
            _blocks[i] = blocks[i];
            _hashs[i] = blockhashes[_blocks[i]];
            if (_hashs[i] == 0)
                _hashs[i] = blockhash(_blocks[i]);
        }
    }

    function calcSuperOdds(uint32 blocknum) public view returns(uint32 oddHi, uint32 oddLo, bytes32 hash) {
        hash = blockhashes[blocknum];
        if (hash == 0) {
            hash = blockhash(blocknum);
        }
        if (hash != 0) {
            uint8 num = uint8(hash[31])&0x0F;
            if (num == 0xf || num == 0xe) {
                oddLo = uint32(uint256(oddsLott+50).mul(10).div(15));
            } else {
                oddLo = uint32(uint256(oddsLott).mul(10).div(num+1));
            }
            if (num == 0x0 || num == 0x1) {
                oddHi = uint32(uint256(oddsLott+50).mul(10).div(15));
            } else {
                oddHi = uint32(uint256(oddsLott).mul(10).div(16-num));
            }
        }
    }

    function superHiLo(uint256 amount) external {
        require(superRoundFinished(), "E");
        takeBetAmount(amount);
        luckyResult(0);
        saveSuperHiloRecord(msg.sender, uint32(block.number), amount);
        saveSuperHiloBlocks(msg.sender, true, uint32(block.number));
        getBlockHash(uint32(block.number));
    }

    function getSuperStep() public view returns(uint32 oddHi, uint32 oddLo, uint256 cashout, bytes32 hash) {
        uint32 blocknum; uint32 _oddHi; uint32 _oddLo;
        bytes32 _hash;
        uint32[] memory blocks = superHiloBlocks[msg.sender];
        if (blocks.length == 0) return (0, 0, 0, 0);
        for (uint i=blocks.length-1; i>=0; i--) {
            if (blocks[i] != 0) {
                blocknum = blocks[i];
                if (blocknum <= uint32(block.number)) {
                    (oddHi, oddLo, hash) = calcSuperOdds(blocknum);
                    (oddHi, _oddLo, _hash) = (oddHi, oddLo, hash);
                }
                if (i >= 1 && blocks[i-1] > 0 && blocks[i-1] <= uint32(block.number)) {
                    (_oddHi, _oddLo, _hash) = calcSuperOdds(blocks[i-1]);
                }
                break;
            }
        }
        if (blocknum == 0 || blocknum > uint32(block.number) || hash == 0) return (0, 0, 0, 0);

        uint8 num = uint8(hash[31])&0x0F;
        uint8 prevNum = uint8(_hash[31])&0x0F;
        uint256 recIdx = history[3][msg.sender].length-1;
        uint256 rec = history[3][msg.sender][recIdx];
        // uint256 bet = (rec >> 32) & 0xffffffffffffffffffffffff;
        uint256 bet = (rec >> 80) & 0xffffffffffff;
        uint32 result = uint32(rec) & 0xffffffff;
        if (result == 3) { // chosen hi
            if ((prevNum > 0x0 && num >= prevNum) ||
                (prevNum == 0x0 && num > prevNum)) {
                cashout = bet.mul(_oddHi).div(1000);
            } else {
                cashout = 0;
            }
        } else if (result == 4 && num <= prevNum) { // chosen lo
            if ((prevNum < 0xf && num <= prevNum) ||
                (prevNum == 0xf && num < prevNum)) {
                cashout = bet.mul(_oddLo).div(1000);
            } else {
                cashout = 0;
            }
        } else {
            cashout = 0;
        }
    }

    function superHi() external {
        require(!superRoundFinished() && getSuperHiloStepCount() < 16, "E");
        (, , uint256 cashout,) = getSuperStep();
        updateSuperHiloRecord(msg.sender, 3, cashout); // temp save choice hi result byte
        saveSuperHiloBlocks(msg.sender, false, uint32(block.number+1));
    }

    function superLo() external {
        require(!superRoundFinished() && getSuperHiloStepCount() < 16, "E");
        (, , uint256 cashout,) = getSuperStep();
        updateSuperHiloRecord(msg.sender, 4, cashout); // temp save choice lo result byte
        saveSuperHiloBlocks(msg.sender, false, uint32(block.number+1));
    }

    function superRoundFinished() public view returns(bool) {
        (, uint256 rec) = verifyRecord(3, 0);
        if (rec == 0) return true;
        (, , , uint256 result) = getRecord(rec);
        if (result == 1 || result == 2) return true; // finished
        if (result == 0) return false; // not play
        (, , uint256 cashout,) = getSuperStep();
        return cashout == 0;
    }

    function superCashOut() public {
        (, uint256 rec) = verifyRecord(3, 0);
        if (rec == 0) return;
        (, , , uint256 result) = getRecord(rec);
        if (result <= 2) return; // not play or finished
        (, , uint256 cashout,) = getSuperStep();
        if (cashout > 0) { // win
            rewardWinner(msg.sender, cashout);
        }
        updateSuperHiloRecord(msg.sender, cashout>0 ? 1:2, cashout);
    }

    function calcEvenOdd(uint256 rec) internal {
        uint256 recIdx;
        (recIdx, rec) = verifyRecord(1, rec);
        if (rec == 0) return;
        (uint32 blocknum, uint256 choice, uint256 bet, uint256 result) = getRecord(rec);
        if (result > 0) return;
        bytes32 hash = getBlockHash(blocknum);
        if (hash == 0) return;
        uint256 amount;
        if ((choice == 0 && (uint8(hash[31]) & 0x0F)%2 == 0)
            || (choice == 1 && (uint8(hash[31]) & 0x0F)%2 == 1)) { // win
            amount = SafeMath.mul(bet, oddsEvenOdd).div(100);
            rewardWinner(msg.sender, amount);  
        }
        updateRecord(1, msg.sender, recIdx, amount);
        emit GameResult(msg.sender, hash, uint8(hash[31])&0x0F, amount);
    }

    function luckyEvenOdd(bool even, uint256 amount) external {
        takeBetAmount(amount);
        luckyResult(0);
        saveRecord(1, msg.sender, even ? 0 : 1, amount);
    }

    function calcLott(uint256 rec) internal {
        uint256 recIdx;
        (recIdx, rec) = verifyRecord(2, rec);
        if (rec == 0) return;
        (uint32 blocknum, uint256 choice, uint256 bet, uint256 result) = getRecord(rec);
        if (result > 0) return;
        bytes32 hash = getBlockHash(blocknum);
        if (hash == 0) return;
        uint8 luckyNum = uint8(hash[31]) & 0x0F;
        uint256 amount;

        uint8 len = 1;
        uint8[] memory numbers = new uint8[](16);
        numbers[0] = uint8((choice >> 60) & 0xf);
        for (uint8 i=1; i<16; i++) {
            numbers[i] = uint8((choice >> (60-i*4)) & 0xf);
            if (numbers[i] == 0) {
                len = i;
                break;
            }
            len = i+1;
        }

        for (uint8 i=0; i<len; i++) {
            if (numbers[i] == luckyNum) {
                amount = SafeMath.mul(bet, oddsLott).div(len).div(100);
                rewardWinner(msg.sender, amount); 
                break;
            }
        }
        updateRecord(2, msg.sender, recIdx, amount);
        emit GameResult(msg.sender, hash, uint8(hash[31])&0x0F, amount);
    }

    function luckyLott(uint8[] memory numbers, uint256 amount) external {
        takeBetAmount(amount);
        luckyResult(0);
        uint256 choice = (uint64(numbers[0])<<60) & 0xf000000000000000;
        for (uint8 i=1; i<numbers.length; i++) {
            choice = choice | ((uint64(numbers[i]) << (60-i*4)) & (0xf << (60-i*4)));
        }
        saveRecord(2, msg.sender, choice, amount);
    }
    
    function sort_array(uint8[] memory arr) private pure returns (uint8[] memory) {
        uint256 l = arr.length;
        for(uint i = 0; i < l; i++) {
            for(uint j = i+1; j < l ;j++) {
                if(arr[i] > arr[j]) {
                    uint8 temp = arr[i];
                    arr[i] = arr[j];
                    arr[j] = temp;
                }
            }
        }
        return arr;
    }

    /**
        //0  22567   double
        //1  22334   two double
        //2  22234   triple
        //3  12345   straights
        //4  22233   double plus triple
        //5  22223   quadruple
        //6  22222   five fold
     */
    function setSlotOdds(uint32[] memory odds) external onlyOwner {
        require(odds.length == 7);
        for (uint8 i=0; i<7; i++) {
            require(odds[i] >= 1000);
            oddsSlot[i] = odds[i];
        }
    }

    function getSlotOdds() external view returns(uint32[] memory) {
        return oddsSlot;
    }

    function getSlotRewards(uint8[] memory slots, uint256 bet) public view returns (uint256, uint8) {
        slots = sort_array(slots);
        bool straights = true;
        uint8 sameNumber = 0x1F;
        uint8 sameCount;
        uint8 pairCount;
        for (uint8 i=0; i<4; i++) {
            if (slots[i] == slots[i+1]) {
                if (sameNumber != slots[i+1]) {
                    pairCount++;
                    sameCount+=2;
                } else {
                    sameCount++;
                }
                sameNumber = slots[i+1];
                straights = false;
            } else if (slots[i]+1 != slots[i+1]) {
                straights = false;
            }
        }
        
        uint8 level = 10;
        if (sameCount == 0 && !straights) return (0, 0); // single
        if (sameCount == 2 && pairCount == 1) { // double
            level = 0;
        } else if (sameCount == 4 && pairCount == 2) { // two double
            level = 1;
        } else if (sameCount == 3 && pairCount == 1) { // triple
            level = 2;
        } else if (straights) { // straights
            level = 3;
        } else if (sameCount == 5 && pairCount == 2) { // double plus triple
            level = 4;
        } else if (sameCount == 4 && pairCount == 1) { // quadruple
            level = 5;
        } else if (sameCount == 5 && pairCount == 1) { // five fold
            level = 6;
        }

        if (level == 10) return (0, 0);
        return (SafeMath.mul(bet, oddsSlot[level]).div(1000), level);
    }

    function calcSlot(uint256 rec) internal {
        uint256 recIdx;
        (recIdx, rec) = verifyRecord(4, rec);
        if (rec == 0) return;
        (uint32 blocknum, , uint256 bet, uint256 result) = getRecord(rec);
        if (result > 0) return;
        bytes32 hash = getBlockHash(blocknum);
        if (hash == 0) return;

        uint8[] memory slots = new uint8[](5);
        slots[0] = uint8(hash[29]) & 0x0F;
        slots[1] = (uint8(hash[30]) >> 4) & 0x0F;
        slots[2] = uint8(hash[30]) & 0x0F;
        slots[3] = (uint8(hash[31]) >> 4) & 0x0F;
        slots[4] = uint8(hash[31]) & 0x0F;

        (uint256 amount, uint8 level) = getSlotRewards(slots, bet);
        if (amount > 0) {
            rewardWinner(msg.sender, amount);
        }
        updateRecord(4, msg.sender, recIdx, amount);
        emit GameResult(msg.sender, hash, level, amount);
    }

    function luckySlot(uint256 amount) external {
        takeBetAmount(amount);
        luckyResult(0);
        saveRecord(4, msg.sender, 0, amount);
    }

    /**
    * game  0: hi/lo  1:even/odd  2: lott  3: super hilo  4: slot
     */
    function getHistory(uint8 game, uint256 size) external view returns(uint256[] memory, bytes32[] memory) {
        require(game >= 0 && game <= 4, "E");
        if (size > 256) size = 256;
        uint256 len = history[game][msg.sender].length;
        if (len < size) {
            size = history[game][msg.sender].length;
        }
        uint256[] memory _rec = new uint256[](size);
        bytes32[] memory _hash = new bytes32[](size);
        uint j = 0;
        for (uint i=len-size; i<len; i++) {
            _rec[j] = history[game][msg.sender][i];
            _hash[j] = blockhashes[uint32((_rec[j] >> 192) & 0xffffffff)];
            j++;
        }

        return (_rec, _hash);
    }

    function hashPeriod() external { // cause contract only get 250 blockhash, should save blockhash from external server
        for (uint32 i=0; i<blocknumbers.length; i++) {
            if (blocknumbers[i] != 0) {
                blockhashes[blocknumbers[i]] = blockhash(blocknumbers[i]);
                blocknumbers[i] = 0;
            }
        }
    }

    function getPendingCount() external view returns(uint32, uint32) {
        uint32 pendingCount = 0;
        for (uint32 i=0; i<blocknumbers.length; i++) {
            if (blocknumbers[i] != 0) {
                pendingCount++;
            }
        }

        return (uint32(blocknumbers.length), pendingCount);
    }

    function fixOutBiasRecord(uint8 game, address adr) external onlyOwner {
        uint256 recIdx = history[game][adr].length-1;
        uint256 rec = history[game][adr][recIdx];
        rec = (rec & 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000) 
            | (2 & 0xfffffff);
        history[game][adr][recIdx] = rec;
    }
}