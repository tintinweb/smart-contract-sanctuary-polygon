// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";


contract Sample is Ownable{


    // 有効投票数
    uint256 validVotesNumber = 3;

    // 投票できるアドレスのリスト
    address[] public whitelistedAddresses;

    // 全コメント数
    uint256 public commentCount;


    // 問題番号 => 問題・解答
    mapping(uint256 => string) public question;
    mapping(uint256 => string) public answer;

    // 問題番号 => コメント数
    mapping(uint256 => uint256) public countByQuestion;

    // コメント番号・インデックス => コメント
    mapping(uint256 =>  mapping(uint256 => string)) public comment;

    // ウォレットアドレス => コメント数
    mapping(address => uint256) public countByAddress;

    // 問題番号 => 投票数
    mapping (uint256 => uint256) public favorNumber;

    // ウォレットアドレス・問題番号　⇨ カウント
    // 問題番号に対して、一人１回まで
    mapping(address =>  mapping(uint256 => uint256)) public userCount;

    // ウォレットアドレス・コメント番号　⇨ コメント
    mapping(address => mapping(uint256 => string)) public commentsByAddress;


    event QuestionSet (
        uint256 indexed _number,
        string question,
        string answer
    );

    event NewComment (
        address indexed from,
        uint256 timestamp,
        string message
    );

    event ValidVote (
        uint256 number
    );

    // 問題作成（オーナーのみ　将来的には管理者権限に変更したい）
    function setQyestions(
        uint256 _number,
        string memory _question,
        string memory _answer
    ) public  onlyOwner {
        question[_number] = _question;
        answer[_number] = _answer;

        emit QuestionSet(_number, _question, _answer);
    }

    // コメントの作成（誰でも可能）
    function newComment(
        uint256 comment_number,
        string memory _comment
    ) public {
        commentCount++;
        countByQuestion[comment_number]++;
        countByAddress[msg.sender]++;
        comment[comment_number][countByQuestion[comment_number]] = _comment;
        commentsByAddress[msg.sender][countByAddress[msg.sender]] = _comment;

        emit NewComment(msg.sender, block.timestamp, _comment);
    }

    // 投票可能者設定（オーナーのみ　将来的には管理者権限に変更したい）
    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    // 投票可能者の確認
    function isWhitelisted(address _user) public view returns (bool) {
        for (uint i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    // 投票実行（ホワイトリスト登録者のみ可能）
    function setFavorNumber (uint256 _number) public {
        require(isWhitelisted(msg.sender), "user is not whitelisted");
        require(userCount[msg.sender][_number] == 0, "you already set favor");
        favorNumber[_number]++;
        userCount[msg.sender][_number]++;
        // 有効投票数の達した時にイベント発生
        if ( favorNumber[_number] == validVotesNumber ) {
            emit ValidVote(_number);
        }
    }

    // 問題変更（投票者のみ変更可能）
    function changeQyestions(
        uint256 _number,
        string memory _question,
        string memory _answer
    ) public {
        require(favorNumber[_number] >= validVotesNumber, "favorNumber is too low");
        require(isWhitelisted(msg.sender), "user is not whitelisted");
        require(userCount[msg.sender][_number] == 1, "you didn't do favor");
        question[_number] = _question;
        answer[_number] = _answer;
        emit QuestionSet(_number, _question, _answer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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