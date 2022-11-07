// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '../interfaces/IPoolListData.sol';
import '../interfaces/IUsersData.sol';
import '../UserPool.sol';

contract UserPoolFactory {
  // POOl
  address POOLLISTDATA_CONTRACT_ADDRESS = 0x35FA06F351ED31f8eAd5DcDF1E586e47fc064376;
  // = poolListDataコントラクトアドレス 先にPoolListDataコントラクトをdeploy
  IPoolListData public poolListData;

  // USER
  address USERS_DATA_CONTRACT_ADDRESS = 0x3B71d3662eF1D13B63a337adA7Fd86C2cDE541a9; // = usersDataコントラクトアドレス 先にUserDataコントラクトをdeploy
  IUsersData public usersData;

  constructor() {
    poolListData = IPoolListData(POOLLISTDATA_CONTRACT_ADDRESS);
    usersData = IUsersData(USERS_DATA_CONTRACT_ADDRESS);
  }

  // Userプール作成
  function newUserPoolFactory(
    address _userAddress,
    string memory _userName,
    string memory _userProfile,
    string memory _userIcon
  ) external returns (address) {
    require(address(poolListData.getMyPoolAddress(_userAddress)) == address(0), 'already created!');

    UserPool userPool = new UserPool(_userAddress, _userName, _userProfile, _userIcon, address(this));
    usersData.addUsers(_userAddress, _userName, _userProfile, _userIcon);
    poolListData.addMyPoolAddress(_userAddress, address(userPool));

    return poolListData.getMyPoolAddress(_userAddress);
  }

  function setPoolListData(address poolListDataAddress) public {
    POOLLISTDATA_CONTRACT_ADDRESS = poolListDataAddress;
    poolListData = IPoolListData(poolListDataAddress);
  }

  function setUsersData(address usersDataAddress) public {
    USERS_DATA_CONTRACT_ADDRESS = usersDataAddress;
    usersData = IUsersData(usersDataAddress);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './interfaces/IUserPool.sol';
import './interfaces/ICheers.sol';
import './interfaces/IProjectsData.sol';
import './interfaces/IERC20.sol';
import './shared/SharedStruct.sol';
import './ProjectPool.sol';

contract UserPool is IUserPool {
  // PROJECT
  address PROJECTSDATA_CONTRACT_ADDRESS = 0x5CE46cA237c357970ee6DCe0e64d1d3dF506514d; // = projectsDataコントラクトアドレス 先にDaoDataコントラクトをdeploy
  IProjectsData public projectsData;

  IERC20 public cher;
  ICheers public cheersDapp;
  address cheersDappAddress;
  address owner;
  address public userAddress;
  string public userName;
  string public userProfile;
  string public userIcon;
  // Alchemy testnet goerli deploy
  address CHER_CONTRACT_ADDRESS = 0xc87D7FE5E5Af9cfEDE29F8d362EEb1a788c539cf;

  // cheerProjectリスト
  address[] cheerProjectList;
  // cheerしているかないか
  mapping(address => bool) public isCheer;

  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }

  constructor(
    address _poolOwnerAddress,
    string memory _userName,
    string memory _userProfile,
    string memory _userIcon,
    address _cheersDappAddress
  ) {
    // CHERコントラクト接続
    cher = IERC20(CHER_CONTRACT_ADDRESS);
    // poolのowner設定
    owner = _poolOwnerAddress;
    userAddress = _poolOwnerAddress;
    userName = _userName;
    userProfile = _userProfile;
    userIcon = _userIcon;
    cheersDappAddress = _cheersDappAddress;
    cheersDapp = ICheers(cheersDappAddress);
    projectsData = IProjectsData(PROJECTSDATA_CONTRACT_ADDRESS);
  }

  // user情報取得関連↓
  // userPoolアドレス取得
  function getUserPoolAddress() public view returns (address) {
    return address(this);
  }

  // userWalletアドレス取得
  function getUserAddress() public view returns (address) {
    return userAddress;
  }

  // user名取得
  function getUserName() public view returns (string memory) {
    return userName;
  }

  // userプロフィール取得
  function getUserProfile() public view returns (string memory) {
    return userProfile;
  }

  // userアイコン取得
  function getUserIcon() public view returns (string memory) {
    return userIcon;
  }

  // userウォレットからuserプールにCHERチャージ
  function chargeCher(uint256 _cherAmount) public onlyOwner {
    require(cher.balanceOf(userAddress) >= _cherAmount, 'not insufficient');
    cher.transferFrom(userAddress, address(this), _cherAmount);
  }

  // userプールからuserウォレットにCHER引出し
  function withdrawCher(uint256 _cherAmount) public onlyOwner {
    require(cher.balanceOf(address(this)) >= _cherAmount, 'not insufficient');
    cher.transfer(userAddress, _cherAmount);
  }

  // Projectプール作成
  function newProjectFactory(
    address _belongDaoAddress,
    string memory _projectName,
    string memory _projectContents,
    string memory _projectReword
  ) public returns (address) {
    ProjectPool projectPool = new ProjectPool(
      address(this),
      _belongDaoAddress,
      _projectName,
      _projectContents,
      _projectReword
    );
    addChallengeProjects(address(projectPool), _belongDaoAddress, _projectName, _projectContents, _projectReword);
    return address(projectPool);
  }

  function addChallengeProjects(
    address projectAddress,
    address _belongDaoAddress,
    string memory _projectName,
    string memory _projectContents,
    string memory _projectReword
  ) private {
    projectsData.addProjects(
      address(this),
      projectAddress,
      _belongDaoAddress,
      _projectName,
      _projectContents,
      _projectReword
    );
  }

  // このuserのChallenge全プロジェクトを取得
  function getAllChallengeProjects() public view returns (SharedStruct.Project[] memory) {
    return projectsData.getEachProjectList(address(this));
  }

  // このuserがCheerしているプロジェクトを追加 ProjectPoolから叩く
  function addCheerProject(address _cheerProjectPoolAddress) external returns (bool) {
    require(!isCheer[_cheerProjectPoolAddress], 'already cheer');

    if (cheerProjectList.length == 0) {
      cheerProjectList.push(_cheerProjectPoolAddress);
      isCheer[_cheerProjectPoolAddress] = true;
    } else {
      for (uint256 i = 0; i < cheerProjectList.length; i++) {
        if (cheerProjectList[i] == _cheerProjectPoolAddress) {
          isCheer[_cheerProjectPoolAddress] = true;
        } else {
          cheerProjectList.push(_cheerProjectPoolAddress);
          isCheer[_cheerProjectPoolAddress] = true;
        }
      }
    }
    return isCheer[_cheerProjectPoolAddress];
  }

  // Cheerしているプロジェクトを脱退 ProjectPoolから叩く
  function removeCheerProject(address _cheerProjectPoolAddress) external returns (bool) {
    require(isCheer[_cheerProjectPoolAddress], 'already not cheer');
    isCheer[_cheerProjectPoolAddress] = false;
    return isCheer[_cheerProjectPoolAddress];
  }

  // このプールのcher総量
  function getTotalCher() public view returns (uint256) {
    return cher.balanceOf(address(this));
  }

  // function setCHER(address CHERAddress) public {
  //   CHER_CONTRACT_ADDRESS = CHERAddress;
  //   cher = IERC20(CHERAddress);
  // }

  // function setProjectsData(address projectsDataAddress) public {
  //   PROJECTSDATA_CONTRACT_ADDRESS = projectsDataAddress;
  //   projectsData = IProjectsData(projectsDataAddress);
  // }

  function approveCherToProjectPool(address _projectPoolAddress, uint256 _cherAmount) external onlyOwner {
    require(cher.balanceOf(address(this)) >= _cherAmount, 'not insufficient');
    cher.approve(_projectPoolAddress, _cherAmount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPoolListData {
  // walletに紐づいたPoolAddress
  function getMyPoolAddress(address _ownerAddress) external view returns (address);

  // walletに紐づいたPoolAddress
  function addMyPoolAddress(address _ownerAddress, address _poolAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '../shared/SharedStruct.sol';

interface IUsersData {
  function addUsers(
    address _userAddress,
    string memory _userName,
    string memory _userProfile,
    string memory _userIcon
  ) external;

  function getAllUserList() external view returns (SharedStruct.User[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUserPool {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ICheers {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './interfaces/IProjectPool.sol';
import './interfaces/IERC20.sol';
import './interfaces/ICheers.sol';
import './interfaces/IPoolListData.sol';
import './interfaces/ICheerListData.sol';
import './shared/SharedStruct.sol';

contract ProjectPool is IProjectPool {
  IERC20 public cher;
  ICheers public cheersDapp;
  address cheersDappAddress;
  address owner;
  address ownerPoolAddress;
  address belongDaoAddress;
  string public projectName;
  string public projectContents;
  string public projectReword;
  // Alchemy testnet goerli deploy
  address CHER_CONTRACT_ADDRESS = 0xc87D7FE5E5Af9cfEDE29F8d362EEb1a788c539cf;

  uint256 public totalCher;

  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }

  // POOl
  address POOLLISTDATA_CONTRACT_ADDRESS = 0x35FA06F351ED31f8eAd5DcDF1E586e47fc064376; // = poolListDataコントラクトアドレス 先にPoolListDataコントラクトをdeploy
  IPoolListData public poolListData;
  address CHEERLISTDATA_CONTRACT_ADDRESS = 0xcE9aDb57464657D74d8A8260b29B29bD07e2c3eb; // = cheerDataコントラクトアドレス 先にPoolListDataコントラクトをdeploy
  ICheerListData public cheerListData;

  constructor(
    address _ownerPoolAddress,
    address _belongDaoAddress,
    string memory _projectName,
    string memory _projectContents,
    string memory _projectReword
  ) {
    poolListData = IPoolListData(POOLLISTDATA_CONTRACT_ADDRESS);
    cheerListData = ICheerListData(CHEERLISTDATA_CONTRACT_ADDRESS);

    //CHERコントラクト接続
    cher = IERC20(CHER_CONTRACT_ADDRESS);
    // cheersDappコントラクト接続
    cheersDapp = ICheers(cheersDappAddress);
    owner = msg.sender;
    ownerPoolAddress = _ownerPoolAddress;
    belongDaoAddress = _belongDaoAddress;
    projectName = _projectName;
    projectContents = _projectContents;
    projectReword = _projectReword;
  }

  // このProjectをCheerする
  function mintCheer(uint256 _cher, string memory _cheerMessage) public {
    require(cher.balanceOf(poolListData.getMyPoolAddress(msg.sender)) >= _cher, 'Not enough');
    cheer(_cher, _cheerMessage);
  }

  // cheerの処理
  function cheer(uint256 _cher, string memory _cheerMessage) private {
    cher.transferFrom(poolListData.getMyPoolAddress(msg.sender), address(this), _cher);
    cheerListData.addCheerDataList(
      address(this),
      poolListData.getMyPoolAddress(msg.sender),
      block.timestamp,
      _cheerMessage,
      _cher
    );
    distributeCher(_cher);
  }

  function distributeCher(uint256 _cher) private {
    // ⚠️端数処理がどうなるか？？？
    // このProjectに投じられた分配前の合計
    totalCher += _cher;
    // cheer全員の分配分
    uint256 cheerDistribute = (_cher * 70) / 100;
    // challengerの分配分
    uint256 challengerDistribute = (_cher * 25) / 100;
    // daoの分配分
    uint256 daoDistribute = _cher - cheerDistribute - challengerDistribute;
    // cheer全員の分配分を投じたcher割合に応じ分配
    for (uint256 i = 0; i < cheerListData.getMyProjectCheerDataList(address(this)).length; i++) {
      cher.transfer(
        cheerListData.getMyProjectCheerDataList(address(this))[i].cheerPoolAddress,
        (cheerDistribute * cheerListData.getMyProjectCheerDataList(address(this))[i].cher) / totalCher
      );
    }
    // challengerのPoolへ分配
    cher.transfer(ownerPoolAddress, challengerDistribute);
    // 所属するDAOへ分配
    cher.transfer(belongDaoAddress, daoDistribute);
  }

  // このプールのcher総量
  function getTotalCher() public view returns (uint256) {
    return cher.balanceOf(address(this));
  }

  // function setCHER(address CHERAddress) public {
  //   CHER_CONTRACT_ADDRESS = CHERAddress;
  //   cher = IERC20(CHERAddress);
  // }

  // function setPoolListData(address poolListDataAddress) public {
  //   POOLLISTDATA_CONTRACT_ADDRESS = poolListDataAddress;
  //   poolListData = IPoolListData(poolListDataAddress);
  // }

  // function setCheerListData(address cheerListDataAddress) public {
  //   CHEERLISTDATA_CONTRACT_ADDRESS = cheerListDataAddress;
  //   cheerListData = ICheerListData(CHEERLISTDATA_CONTRACT_ADDRESS);
  // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '../shared/SharedStruct.sol';

interface IProjectsData {
  // PROJECT追加
  function addProjects(
    address _projectOwnerAddress,
    address _projectPoolAddress,
    address _belongDaoAddress,
    string memory _projectName,
    string memory _projectContents,
    string memory _projectReword
  ) external;


  // アドレスごとのProject取得
  function getEachProjectList(address _projectOwnerAddress) external view returns (SharedStruct.Project[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library SharedStruct {
  struct Dao {
    address daoAddress;
    string daoName;
    string daoProfile;
    string daoIcon;
    uint256 creationTime;
  }

  struct User {
    address userAddress;
    string userName;
    string userProfile;
    string userIcon;
    uint256 creationTime;
  }

  struct Project {
    address projectOwnerAddress;
    address projectAddress;
    address belongDaoAddress;
    string projectName;
    string projectContents;
    string projectReword;
    uint256 creationTime;
  }

  struct Cheer {
    address projectAddress;
    address cheerPoolAddress;
    uint256 creationTime;
    string message;
    uint256 cher;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IProjectPool {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '../shared/SharedStruct.sol';

interface ICheerListData {
  function addCheerDataList(
    address _projectPoolAddress,
    address _cheerPoolAddres,
    uint256 _creationTime,
    string memory _message,
    uint256 _cher
  ) external;

  function getMyPoolCheerDataList(address _cheerPoolAddress) external view returns (SharedStruct.Cheer[] memory);

  function getMyProjectCheerDataList(address _projectPoolAddress) external view returns (SharedStruct.Cheer[] memory);
}