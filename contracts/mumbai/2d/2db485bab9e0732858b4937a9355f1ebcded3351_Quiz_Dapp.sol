/**
 *Submitted for verification at polygonscan.com on 2023-06-01
*/

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

// File: @openzeppelin/[email protected]/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/[email protected]/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/[email protected]/token/ERC20/ERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: quiz/class_room.sol


pragma solidity ^0.8.2;


contract class_room{
    mapping (address=>bool) private  teachers;
    mapping (address=>bool) private  students;

    address [] teacher_address_list;
    address [] student_address_list;

    constructor() {
        teachers[msg.sender]=true;
        teacher_address_list.push(msg.sender);
    }
    modifier isTeacher() {
        require(teachers[msg.sender] == true, "Caller is not teachers");
        _;
    }
    function check_teacher(address _target) internal view returns(bool res){
        res=teachers[_target];
    }
    function add_teacher(address teacher_address)public isTeacher()  returns (bool res){
        if(teachers[teacher_address]==false){
            teachers[teacher_address]=true;
            teacher_address_list.push(teacher_address);
        }
        res=true;//await　への返答
    }


    function add_student(address [] memory students_address)public isTeacher() returns (bool res){
        for(uint i=0;i<students_address.length;i++){
            if(students[students_address[i]]==false){
                students[students_address[i]]=true;
                student_address_list.push(students_address[i]);//同一のユーザーを追加しないように
            }
        }
        res=true;
    } 

    function get_student_all()public view  isTeacher returns (address [] memory result ){
        result=student_address_list;
    }

    function get_teacher_all()public view  isTeacher returns (address [] memory result ){
        result=teacher_address_list;
    }

}

// File: quiz/quiz.sol


pragma solidity ^0.8.2;


contract Quiz_Dapp is class_room {
    address Token_address=0xE5ffF15fE09612862BBDcCbd744435419FEaed22;
    TokenInterface token =  TokenInterface(Token_address);

    struct User{
        string user_id;
        string img_url;
        uint result;
    }

    mapping (address=>User) private users;
    constructor() {
        
            
        
    }



    struct Quiz{
        uint quiz_id;//対象となるリクエストのid
        address owner;//出題者
        string title;
        string explanation;
        string thumbnail_url;
        string content;
        uint answer_type;//0,選択しき/1,記述
        string answer_data;
        bytes32 answer_hash;//回答をハッシュ化したものを格納
        uint create_time_epoch;
        uint time_limit_epoch;
        uint reward;
        uint respondent_count;
        uint respondent_limit;
        mapping  (address=>uint)respondents_map;//0が未回答,1が不正解,2が正解
        mapping (address=>uint)respondents_state;
        Answer[] answers;
    }
    struct Answer{
        address respondent;
        uint answer_time;
        uint reward;
        bool result;
    }
    
    Quiz[] private  quizs;

    event Create_quiz(address indexed _sender,uint indexed id);
    function create_quiz(string memory _title,string memory _explanation,string memory _thumbnail_url,string memory _content,uint _answer_type,string memory _answer_data,string  memory _answer,uint _timelimit_after_epoch,uint _reward,uint _respondent_limit) public returns (uint id){
        require(token.allowance(msg.sender,address(this)) >= _reward * _respondent_limit,"Not enough token approve fees");
        token.transferFrom_explanation(msg.sender, address(this), _reward * _respondent_limit*10**token.decimals(),"create_quiz");
        id = quizs.length;
        quizs.push();
        bytes32 answer_hash=keccak256(abi.encodePacked(_answer));
        // quizs.push(Quiz(id,msg.sender,_title,_thumbnail_url,_content,_choices,answer_hash,answer_hash,block.timestamp,_reward,_respondent_limit,Answer(msg.sender,block.timestamp,0)));
        quizs[id].owner=msg.sender;
        quizs[id].title=_title;
        quizs[id].explanation=_explanation;
        quizs[id].thumbnail_url=_thumbnail_url;
        quizs[id].content=_content;
        quizs[id].answer_type=_answer_type;
        quizs[id].answer_data=_answer_data;
        quizs[id].answer_hash=answer_hash;
        quizs[id].create_time_epoch=block.timestamp;
        quizs[id].time_limit_epoch=_timelimit_after_epoch;
        quizs[id].reward=_reward;
        quizs[id].respondent_count=0;
        quizs[id].respondent_limit=_respondent_limit;
        emit Create_quiz(msg.sender, id);
        return id;
    }

    function get_quiz(uint _quiz_id)public view returns(uint id,address owner,string memory title,string memory explanation,string memory thumbnail_url,string memory content,string memory answer_data,uint create_time_epoch,uint time_limit_epoch,uint reward,uint respondent_count,uint respondent_limit){
        id=_quiz_id;
        owner=quizs[_quiz_id].owner;
        title=quizs[_quiz_id].title;
        explanation=quizs[_quiz_id].explanation;
        thumbnail_url=quizs[_quiz_id].thumbnail_url;
        content=quizs[_quiz_id].content;
        answer_data=quizs[_quiz_id].answer_data;
        time_limit_epoch=quizs[_quiz_id].time_limit_epoch;
        create_time_epoch=quizs[_quiz_id].create_time_epoch;
        reward=quizs[_quiz_id].reward;
        respondent_count=quizs[_quiz_id].respondent_count;
        respondent_limit=quizs[_quiz_id].respondent_limit;
    }
    function get_quiz_answer_type(uint _quiz_id)public view returns (uint answer_type){
        answer_type=quizs[_quiz_id].answer_type;
    }
    function get_quiz_simple(uint _quiz_id)public view returns(uint id,address owner,string memory title,string memory explanation,string memory thumbnail_url,uint time_limit_epoch,uint reward,uint respondent_count,uint respondent_limit,uint state){
        id=_quiz_id;
        owner=quizs[_quiz_id].owner;
        title=quizs[_quiz_id].title;
        explanation=quizs[_quiz_id].explanation;
        thumbnail_url=quizs[_quiz_id].thumbnail_url;
        time_limit_epoch=quizs[_quiz_id].time_limit_epoch;
        reward=quizs[_quiz_id].reward;
        respondent_count=quizs[_quiz_id].respondent_count;
        respondent_limit=quizs[_quiz_id].respondent_limit;
        state=quizs[_quiz_id].respondents_map[msg.sender];
    }


    event Post_answer(address indexed _sender,uint indexed quiz_id,uint indexed answer_id);
    function post_answer(uint _quiz_id,string memory _answer)public returns(uint answer_id,uint reward){
        require(quizs[_quiz_id].respondent_count<quizs[_quiz_id].respondent_limit,"You have reached the maximum number of responses");
        //require(quizs[_quiz_id].respondents_map[msg.sender]==0,"already answered");
        require(quizs[_quiz_id].time_limit_epoch>=block.timestamp,"end quiz");
        bytes32 answer_hash=keccak256(abi.encodePacked(_answer));
        bool result;
        if(answer_hash==quizs[_quiz_id].answer_hash){
            
            
            if(check_teacher(quizs[_quiz_id].owner)==true && quizs[_quiz_id].respondents_map[msg.sender]==0){ //教員から出された問題であれば結果に反映　&& 初回の回答であれば
                reward =quizs[_quiz_id].reward;
                quizs[_quiz_id].respondent_count+=1;
                users[msg.sender].result+=reward*10**token.decimals();
                token.transfer_explanation(msg.sender, reward*10**token.decimals(),"correct answer");
            }
            else if (check_teacher(quizs[_quiz_id].owner)==true && quizs[_quiz_id].respondents_map[msg.sender]==1){ //教員から出された問題であれば結果に反映　&& 間違った回答をした後であれば
                token.transfer_explanation(msg.sender, 0,"correct answer");
            }
            result=true;
            quizs[_quiz_id].respondents_map[msg.sender]=2;
        }
        else{
            reward=0;
            token.transfer_explanation(msg.sender, 0,"Incorrect answer");
            result=false;
            quizs[_quiz_id].respondents_map[msg.sender]=1;
        }
        
        answer_id=quizs[_quiz_id].answers.length;
        quizs[_quiz_id].respondents_state[msg.sender]=answer_id;
        quizs[_quiz_id].answers.push();
        quizs[_quiz_id].answers[answer_id].respondent=msg.sender;
        quizs[_quiz_id].answers[answer_id].answer_time=block.timestamp;
        quizs[_quiz_id].answers[answer_id].reward=reward;
        quizs[_quiz_id].answers[answer_id].result=result;


        emit Post_answer(msg.sender,_quiz_id,answer_id);
    }
    function post_answer_view(uint _quiz_id,string memory _answer)public view returns(bool result){
        bytes32 answer_hash=keccak256(abi.encodePacked(_answer));
        result=false;
        if(answer_hash==quizs[_quiz_id].answer_hash){
            result=true;
        }
    }


    function get_quiz_respondent(uint _quiz_id,uint answer_id)public view returns(address respondent,uint answer_time,uint reward,bool result){
        respondent=quizs[_quiz_id].answers[answer_id].respondent;
        answer_time=quizs[_quiz_id].answers[answer_id].answer_time;
        reward=quizs[_quiz_id].answers[answer_id].reward;
        result=quizs[_quiz_id].answers[answer_id].result;
    }

    function get_quiz_length()public view returns (uint length){
        length=quizs.length;
    }

    function set_user_name(string memory _user_name) public returns (bool){
        users[msg.sender].user_id=_user_name;
        return true;
    }
    function set_user_img(string memory _user_img) public returns (bool){
        users[msg.sender].img_url=_user_img;
        return true;
    }
    function get_user(address _target)public view returns (string memory student_id,string memory img_url,uint result,bool state){
        if(_target==msg.sender){
            student_id=users[_target].user_id;
            img_url=users[_target].img_url;
            result=users[_target].result;
            if(bytes(users[_target].user_id).length==0){//文字列が空であれば
                state=false;
            }
            else{
                state=true;
            }
        }
    }

    struct Result{
        address student;
        uint result;
    }
    function get_student_results()public view isTeacher() returns (Result [] memory){
        address [] memory students=get_student_all();
        Result [] memory results=new Result [](students.length);
        for (uint i =0 ;i< students.length ;i++){
            results[i].student=students[i];
            results[i].result=users[students[i]].result;
        }
        return results;
    }
    
}
interface TokenInterface {
    function name() external view returns (string memory );
    function symbol() external view returns (string memory);
    function decimals() external  view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external  view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external  returns (bool success);
    function transfer_explanation(address _to, uint256 _value,string memory _explanation) external  returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external  returns (bool success);
    function transferFrom_explanation(address sender,address recipient,uint256 amount,string memory _explanation)external  returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function approve_explanation(address _spender, uint256 _value,string memory _explanation) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}