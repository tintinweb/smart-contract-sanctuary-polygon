/**
 *Submitted for verification at polygonscan.com on 2023-06-15
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract ERC721 {

    // 선언
    string private _name; // 토큰 이름
    string private _symbol; // 토큰 심볼
    string private _baseURI; // 토큰의 베이스 주소
    uint private _totalSupply; // 총 발행량
    address internal _adAddr; // 생성자 & 관리자 어드레스
    address internal _lockAddr; // 락 어드레스 address(0x000000000000000000000000000000000000dEaD)

    // 매핑(데이터저장)
    mapping(address => uint256) private _balances; // 주소를 입력 후 발란스 저장
    mapping(uint256 => address) private _owners; // 토큰아이디 압력 후 소유자 어드레스 저장
    mapping(uint256 => string) private _tokenInfo; // 토큰아이디 입력 후 토큰URI 저장
    mapping(uint256 => address) private _tokenApprovals; // 토큰아이디 입력 후 권한위임 어드레스 저장
    mapping(address => mapping(address => bool)) private _operatorApprovals; // 소유자와 권한위임 주소를 입력 후 불리언으로 저장

    // 이벤트(실행)
    event Transfer(address from, address to, uint256 tokenId); // from -> to 어드레스로 토큰아이디 전송
    event Approval(address from, address to, uint256 tokenId); // from -> to 어드레스로 토큰아이디 권한 위임
    event ApprovalForAll(address from, address operator, bool approval); // from -> operator 어드레스로 토큰 전체 권한 위임

    // 컨스트럭처(최초실행 - 기본설정)
    constructor(string memory name_, string memory symbol_, string memory baseURI_) {
        _name = name_; // 기재한 토큰 이름으로 초기세팅
        _symbol = symbol_; // 기재한 토큰 심볼로 초기세팅
        _baseURI = baseURI_; // 기재한 토큰의 베이스주소로 초기세팅
        _lockAddr = address(0x000000000000000000000000000000000000dEaD); // 락 어드레스 주소 초기세팅
        _adAddr = msg.sender; // 관리자 어드레스 주소 초기세팅
    }

    // 모디파이어(공통실행 - 토큰아이디의 대한 소유자 확인)
    modifier checkOwner(uint256 tokenId) {
        require(_owners[tokenId] == msg.sender, "Incorrect Owner"); // 소유자 체크
        _;
    }

    /* 
    * ==================================================
    * 등록처리
    * 가스비 발생
    * ==================================================
    */ 

    // 컨트렉트 관리자 갱신
    function setAdmin(address adAddr_) public {
        _adAddr = adAddr_; // 입력받은 어드레스로 컨트렉트 관리자를 갱신한다.
    }

    // 베이스URI 등록
    function setBaseURI(string memory baseURI_) public {
        _baseURI = baseURI_; // 입력받은 베이스URI 를 기존 베이스URI에 갱신한다.
    }

    // 민트
    function mint(address to, uint256 tokenId, string memory tokenURI_) public {
        require(!existsTokenId(tokenId), "NFT721 : token already minted"); // 제로어드레스가 아닌 어드레스로 이미 발행되었다면?
        
        _beforeTokenTransfer(address(0), to, tokenId, 1);

        _balances[to] += 1; // 받는사람의 발란스를 +1 증가
        _owners[tokenId] = to; // 토큰아이디의 소유자를 to로 등록
        _tokenInfo[tokenId] = tokenURI_; // 토큰아이디의 토큰URI 등록
        _totalSupply += 1; // 총 발행량을 +1 증가
        
        emit Transfer(address(0), to, tokenId); // 제로어드레스에서 to 에게 토큰아이디 발행

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    // 번(address(0) 제로어드레스)
    function burn(uint256 tokenId) public {
        address owner = _owners[tokenId]; // 번할 토큰의 소유자 확인
        _balances[owner] -= 1; // 번할 토큰 소유자의 발란스 -1 차감
        delete _owners[tokenId]; // 번할 토큰의 기존 소유자 소멸
        delete _tokenApprovals[tokenId]; // 번할 토큰의 권한 소멸
        emit Transfer(owner, address(0), tokenId); // 기존 소유자가 제로어드레스로 토큰아이디 전송
    } 

    // 락(Dead어드레스로 전송하여 컨트렉트에서 기능을 제한한다. - Dead어드레스는 opensea 표준 락 어드레스)
    function lock(uint256 tokenId) public {
        address owner = _owners[tokenId]; // 락할 토큰의 소유자 확인
        _balances[owner] -= 1; // 락할 토큰 소유자의 발란스 -1 차감
        delete _owners[tokenId]; // 락할 토큰의 기존 소유자 소멸
        delete _tokenApprovals[tokenId]; // 락할 토큰의 소유자 권한 소멸
        _owners[tokenId] = _lockAddr; // 토큰의 대한 소유자를 락어드레스로 등록(표준어드레스가 아니므로 소유자를 지정)
        emit Transfer(owner, _lockAddr, tokenId); // 기존 소유자가 락어드레스로 토큰아이디 전송(함수별 _lockAddr 어드레스의 대한 require 설정)
    }

    /*
    * 언락(Dead어드레스에서 기존사용자 사용가능하게 락해제)
    * address to 를 기입받는게 아니라, 기존 사용자로 다시 처리해줘야 하는 상황
    * 본인의 소유자 확인 프로세스 구성 방법
    */
    function unLock(address to, uint256 tokenId) public {
        address owner = _owners[tokenId]; // 언락 할 토큰의 소유자 확인
        delete _owners[tokenId]; // 언락 할 토큰의 기존 소유자 소멸
        delete _tokenApprovals[tokenId]; // 언락할 토큰의 소유자 권한 소멸
        _balances[to] += 1; // 받을 사람의 발란스 +1 증가
        _owners[tokenId] = to; // 토큰의 소유자를 to 로 지정
        emit Transfer(owner, to, tokenId); // 락어드레스에서 to 어드레스에게 토큰 전송
    }

    // 어프로발(토큰아이디의 대한 권한 위임 - modifier checkOwner 소유자 확인 검증)
    function approval(address to, uint256 tokenId) public checkOwner(tokenId) {
        // require(_owners[tokenId] == msg.sender, "Incorrect Owner"); // 소유자 체크
        _tokenApprovals[tokenId] = to; // 해당토큰의 권한을 to 에게 위임
        emit Approval(_owners[tokenId], to, tokenId); // 토큰의 소유자가 to 어드레스에게 해당토큰의 권한을 위임 실행
    }

    // 어프로발프롬(소유자의 모든 토큰의 권한을 위임)
    function setApprovalForAll(address owner, address operator, bool approved) public {
        _operatorApprovals[owner][operator] = approved; // 소유자가 위임자어드레스에 권한위임을 true/false 설정
        emit ApprovalForAll(owner, operator, approved); // 소유자가 위임자어드레스에 등록된 approved true/false 실행
    }

    // 전송(소유자가 받은사람에게 토큰아이디를 전송)
    function transfer(address to, uint256 tokenId) public {
        require(_owners[tokenId] == msg.sender, "Incorrect Owner"); // 토큰의 소유자가 맞는지 검증
        
        delete _owners[tokenId]; // 토큰의 기존 소유자 소멸
        delete _tokenApprovals[tokenId]; // 토큰의 기존 사용자 권한 소멸
        _balances[msg.sender] -= 1; // 기존 사용자 발란스 -1차감

        _balances[to] += 1; // 받는사람 발란스 +1 추가
        _owners[tokenId] = to; // 토큰의 소유자를 to 어드레스로 설정

        emit Transfer(msg.sender, to, tokenId); // 기존사용자가 to 어드레스로 토큰아이디 전송
    }

    // 전송(소유자 또는 권한위임자 가 기존소유자를 이용하여 받는사람에게 토큰아이디를 전송)
    function transferForm(address from, address to, uint256 tokenId) public {
        address owner = _owners[tokenId]; // 토큰아이디의 대한 소유자 확인

        /*
        * 검증(msg.sender 가 1~3번중에서 해당되는 것이 있다면 전송가능)
        * 1. 소유자가 맞는지
        * 2. 토큰의 권한을 위임 받았는지
        * 3. 소유자의 모든 권한을 위임 받았는지
        */
        require((owner == msg.sender) || (getApproval(tokenId) == msg.sender) || (isApprovedForAll(owner, msg.sender)), "Not Approved");

        delete _owners[tokenId]; // 해당토큰의 소유자 소멸
        delete _tokenApprovals[tokenId]; // 해당토큰의 기존 사용자 권한 소멸
        _balances[from] -= 1; // 소유자의 발란스 -1 차감;

        _balances[to] += 1; // 받는사람 발란스 +1 추가
        _owners[tokenId] = to; // 토큰의 소유자를 to 어드레스로 설정

        emit Transfer(from, to, tokenId); // 소유자가 to 어드레스로 토큰아이디를 전송

    }

    /* 
    * ==================================================
    * 읽기전용
    * 가스비 X
    * ==================================================
    */ 

    // 관리자(getAdmin - 컨트렉트의 관리자를 확인)

    // 이름(name - 발행된 토큰의 대표 이름을 확인)
    function name() public view returns(string memory) {
        return _name;
    }

    // 심볼(symbol - 발행된 토큰의 대표 심볼을 확인)
    function symbol() public view returns(string memory) {
        return _symbol;
    }

    // 베이스URI(getBaseURI - 발행된 토큰의 대표 베이스주소를 확인)
    function baseURI() public view returns(string memory) {
        return _baseURI;
    }

    // 토큰정보(tokenURI - 해당 토큰의 메타데이터 정보를 확인)
    function tokenURI(uint256 tokenId) public view returns(string memory) {
        // return string(abi.encodePacked(_baseURI,_tokenInfo[tokenId],".json")); // tring(abi.encodePacked() 문자열 합치기
        return string(abi.encodePacked(_baseURI,_tokenInfo[tokenId])); // tring(abi.encodePacked() 문자열 합치기
    }

    // 토큰존재유무(existsTokenId - 제로 어드레스가 아닌 토큰아이디의 존재유무를 확인)
    function existsTokenId(uint256 tokenId) public view returns(bool) {
        return _owners[tokenId] != address(0); // 제로어드레스가 아닌 토큰의 true/false 리턴
    } 

    // 토탈서플라이(totalSupply - 총 발행량을 확인)
    function totalSupply() public view returns(uint) {
        return _totalSupply;
    }

    // 발란스(balanceOf - 어드레스를 입력하여 토큰의 발란스를 확인)
    function balanceOf(address owner) public view returns(uint256) {
        return _balances[owner];
    }

    // 소유자(ownerOf - 토큰아이디를 입력하여 소유자 어드레스를 확인)
    function ownerOf(uint256 tokenId) public view returns(address) {
        return _owners[tokenId];
    }

    // 토큰위임권한(getApproval - 토큰아이디의 대한 권한 위임이 있는 어드레스를 확인)
    function getApproval(uint256 tokenId) public view returns(address) {
        return _tokenApprovals[tokenId];
    }

    // 토큰위임권한전체(isApprovedForAll - 지정한 오너의 대한 모든 토큰 권한 위임이 있는 어드레스를 확인)
    function isApprovedForAll(address owner, address operator) public view returns(bool) {
        return _operatorApprovals[owner][operator];
    }

}