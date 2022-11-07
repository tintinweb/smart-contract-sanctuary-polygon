// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '../interfaces/IPoolListData.sol';
import '../interfaces/IDaosData.sol';
import '../DaoPool.sol';

contract DaoPoolFactory {
  // POOl
  address POOLLISTDATA_CONTRACT_ADDRESS = 0x35FA06F351ED31f8eAd5DcDF1E586e47fc064376; // = poolListDataコントラクトアドレス 先にPoolListDataコントラクトをdeploy
  IPoolListData public poolListData;

  // USER
  address DAOS_DATA_CONTRACT_ADDRESS = 0xa1c94AE2029Ef112386707A9DbD5501FCAfD37c4; // = usersDataコントラクトアドレス 先にUserDataコントラクトをdeploy
  IDaosData public daosData;

  constructor() {
    poolListData = IPoolListData(POOLLISTDATA_CONTRACT_ADDRESS);
    daosData = IDaosData(DAOS_DATA_CONTRACT_ADDRESS);
  }

  // Daoプール作成
  function newDaoPoolFactory(
    address _daoAddress,
    string memory _daoName,
    string memory _daoProfile,
    string memory _daoIcon
  ) external returns (address) {
    require(address(poolListData.getMyPoolAddress(_daoAddress)) == address(0), 'already created!');

    DaoPool daoPool = new DaoPool(_daoAddress, _daoName, _daoProfile, _daoIcon, address(this));
    daosData.addDaos(_daoAddress, _daoName, _daoProfile, _daoIcon);
    poolListData.addMyPoolAddress(_daoAddress, address(daoPool));

    return poolListData.getMyPoolAddress(_daoAddress);
  }

  function setPoolListData(address poolListDataAddress) public {
    POOLLISTDATA_CONTRACT_ADDRESS = poolListDataAddress;
    poolListData = IPoolListData(poolListDataAddress);
  }

  function setDaosData(address daosDataAddress) public {
    DAOS_DATA_CONTRACT_ADDRESS = daosDataAddress;
    daosData = IDaosData(daosDataAddress);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './interfaces/IDaoPool.sol';
import './interfaces/ICheers.sol';
import './interfaces/IProjectsData.sol';
import './interfaces/IERC20.sol';
import './shared/SharedStruct.sol';
import './ProjectPool.sol';

contract DaoPool is IDaoPool {
  // PROJECT
  address PROJECTSDATA_CONTRACT_ADDRESS = 0x5CE46cA237c357970ee6DCe0e64d1d3dF506514d; // = projectsDataコントラクトアドレス 先にDaoDataコントラクトをdeploy
  IProjectsData public projectsData;

  IERC20 public cher;
  ICheers public cheersDapp;
  address cheersDappAddress;
  address owner;
  address public daoAddress;
  string public daoName;
  string public daoProfile;
  string public daoIcon;
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
    string memory _daoName,
    string memory _daoProfile,
    string memory _daoIcon,
    address _cheersDappAddress
  ) {
    // CHERコントラクト接続
    cher = IERC20(CHER_CONTRACT_ADDRESS);
    // poolのowner設定
    owner = _poolOwnerAddress;
    daoAddress = _poolOwnerAddress;
    daoName = _daoName;
    daoProfile = _daoProfile;
    daoIcon = _daoIcon;
    cheersDappAddress = _cheersDappAddress;
    cheersDapp = ICheers(cheersDappAddress);
    projectsData = IProjectsData(PROJECTSDATA_CONTRACT_ADDRESS);
  }

  // DAO情報取得関連↓
  // DAOPoolアドレス取得
  function getDaoPoolAddress() public view returns (address) {
    return address(this);
  }

  // DaoWalletアドレス取得
  function getDaoAddress() public view returns (address) {
    return daoAddress;
  }

  // DAO名取得
  function getDaoName() public view returns (string memory) {
    return daoName;
  }

  // DAOプロフィール取得
  function getDaoProfile() public view returns (string memory) {
    return daoProfile;
  }

  // DAOアイコン取得
  function getDaoIcon() public view returns (string memory) {
    return daoIcon;
  }

  // DAOウォレットからDAOプールにCHERチャージ
  function chargeCher(uint256 _cherAmount) public onlyOwner {
    require(cher.balanceOf(daoAddress) >= _cherAmount, 'not insufficient');
    cher.transferFrom(daoAddress, address(this), _cherAmount);
  }

  // DAOプールからDAOウォレットにCHER引出し
  function withdrawCher(uint256 _cherAmount) public onlyOwner {
    require(cher.balanceOf(address(this)) >= _cherAmount, 'not insufficient');
    cher.transfer(daoAddress, _cherAmount);
  }

  // Projectプール作成
  function newProjectFactory(
    string memory _projectName,
    string memory _projectContents,
    string memory _projectReword
  ) public returns (address) {
    ProjectPool projectPool = new ProjectPool(
      address(this),
      address(this),
      _projectName,
      _projectContents,
      _projectReword
    );
    addChallengeProjects(address(projectPool), address(this), _projectName, _projectContents, _projectReword);
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

  // このDAOのChallenge全プロジェクトを取得
  function getAllChallengeProjects() public view returns (SharedStruct.Project[] memory) {
    return projectsData.getEachProjectList(address(this));
  }

  // このDAOがCheerしているプロジェクトを追加 ProjectPoolから叩く
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

import '../shared/SharedStruct.sol';

interface IDaosData {
  function addDaos(
    address _daoAddress,
    string memory _daoName,
    string memory _daoProfile,
    string memory _daoIcon
  ) external;

  function getAllDaoList() external view returns (SharedStruct.Dao[] memory);
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

interface IDaoPool {
  function addCheerProject(address projectPoolAddress) external returns (bool);

  function removeCheerProject(address projectPoolAddress) external returns (bool);
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

interface ICheers {}

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