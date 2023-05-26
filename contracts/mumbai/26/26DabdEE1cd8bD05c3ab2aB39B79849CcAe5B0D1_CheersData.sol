// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/ICheersData.sol";
import "./interfaces/IProjectPool.sol";
import "./shared/SharedStruct.sol";

// データ保存のためのコントラクト
contract CheersData is ICheersData {
  // DAOのデータ
  SharedStruct.Owner[] public daosData;
  // userのデータ
  SharedStruct.Owner[] public usersData;

  // Challengerのアドレス => Challengeしたインデックスの配列
  mapping(address => uint256[]) public projectsIndexOfChallenger;

  // projectPoolにcheerしているかないかのフラグ
  mapping(address => mapping(address => bool)) public isCheer;

  // cheerer（userやDAO）のアドレス => Cheerしたデータの配列
  mapping(address => uint256[]) public cheersIndexByCheerer;

  // projectプールのアドレス => Cheerされたデータの配列
  mapping(address => uint256[]) public cheersIndexOfProject;

  // 全てのProjectsDataの配列
  SharedStruct.Project[] public allProjectsData;

  // 全てのCheerの情報の配列
  SharedStruct.Cheer[] public allCheersData;

  // プロジェクトプールのアドレス => そのプロジェクトのインデックス
  mapping(address => uint256) public projectIndexByProjectAddress;

  // Owner（userやDAO）を追加
  // @note PoolFactoryのみ実行
  function addOwnerData(
    address _ownerAddress,
    string memory _ownerName,
    string memory _ownerProfile,
    string memory _ownerIcon,
    bool _isDao
  ) external {
    if (_isDao == true) {
      daosData.push(
        SharedStruct.Owner({
          ownerCreationTime: block.timestamp,
          ownerAddress: _ownerAddress,
          ownerName: _ownerName,
          ownerProfile: _ownerProfile,
          ownerIcon: _ownerIcon
        })
      );
    } else {
      usersData.push(
        SharedStruct.Owner({
          ownerCreationTime: block.timestamp,
          ownerAddress: _ownerAddress,
          ownerName: _ownerName,
          ownerProfile: _ownerProfile,
          ownerIcon: _ownerIcon
        })
      );
    }
  }

  // 全てのDAOのデータを取得
  function getAllDaosData() public view returns (SharedStruct.Owner[] memory) {
    return daosData;
  }

  // 全てのuserのデータを取得
  function getAllUsersData() public view returns (SharedStruct.Owner[] memory) {
    return usersData;
  }

  // CheerDataを追加
  // @note ProjectPoolのみ実行
  function addCheerData(
    address _cheerProjectAddress,
    address _ownerAddress,
    uint256 _cheerCreationTime,
    string memory _cheerMessage,
    uint256 _cheerCherAmount
  ) external {
    allCheersData.push(
      SharedStruct.Cheer({
        cheerCherAmount: _cheerCherAmount,
        cheerCreationTime: _cheerCreationTime,
        cheerProjectAddress: _cheerProjectAddress,
        cheerAddress: _ownerAddress,
        cheerMessage: _cheerMessage
      })
    );

    uint256 cheersIndex = allCheersData.length - 1;
    cheersIndexByCheerer[_ownerAddress].push(cheersIndex);
    cheersIndexOfProject[_cheerProjectAddress].push(cheersIndex);
  }

  // cheererがcheerしたCheersDataを取得する
  function getCheersDataByCheerer(address _ownerAddress) public view returns (SharedStruct.Cheer[] memory) {
    return _getCheersDataByIndexes(cheersIndexByCheerer[_ownerAddress]);
  }

  // projectをcheerしたCheersDataを取得する
  function getCheersDataOfProject(address _projectAddress) public view returns (SharedStruct.Cheer[] memory) {
    return _getCheersDataByIndexes(cheersIndexOfProject[_projectAddress]);
  }

  // Projectを追加
  // @note Poolのみ実行
  function addProject(
    address _projectChallengerAddress,
    address _projectAddress,
    address _projectBelongDaoAddress,
    string memory _projectName,
    string memory _projectContent,
    string memory _projectReword
  ) external {
    uint256 _projectCreationTime = block.timestamp;

    allProjectsData.push(
      SharedStruct.Project({
        projectChallengerAddress: _projectChallengerAddress,
        projectAddress: _projectAddress,
        projectBelongDaoAddress: _projectBelongDaoAddress,
        projectName: _projectName,
        projectContent: _projectContent,
        projectReword: _projectReword,
        projectCreationTime: _projectCreationTime
      })
    );
    uint256 projectIndex = allProjectsData.length - 1;
    projectsIndexOfChallenger[_projectChallengerAddress].push(projectIndex);
    projectIndexByProjectAddress[_projectAddress] = projectIndex;
  }

  // ProjectPoolのアドレスからProjectDataを取得
  function getProjectDataByProjectAddress(address _projectAddress) public view returns (SharedStruct.Project memory) {
    return allProjectsData[projectIndexByProjectAddress[_projectAddress]];
  }

  // addressごとの配列を取得
  function _getCheersDataByIndexes(uint256[] memory _indexArray) internal view returns (SharedStruct.Cheer[] memory) {
    uint256 _indexArrayLength = _indexArray.length;
    SharedStruct.Cheer[] memory _cheersData = new SharedStruct.Cheer[](_indexArrayLength);

    for (uint256 i = 0; i < _indexArrayLength; ) {
      _cheersData[i] = allCheersData[_indexArray[i]];
      unchecked {
        ++i;
      }
    }

    return _cheersData;
  }

  // challengerごとのProjectsData（配列）を取得
  function getProjectsDataOfChallenger(address _challengerAddress) public view returns (SharedStruct.Project[] memory) {
    uint256[] memory _projectsIndex = projectsIndexOfChallenger[_challengerAddress];
    uint256 _projectsIndexLength = _projectsIndex.length;
    SharedStruct.Project[] memory _projectsData = new SharedStruct.Project[](_projectsIndexLength);

    for (uint256 i = 0; i < _projectsIndexLength; ) {
      _projectsData[i] = allProjectsData[_projectsIndex[i]];
      unchecked {
        ++i;
      }
    }

    return _projectsData;
  }

  // 全てのProjectsData（配列）を取得
  function getAllProjectsData() public view returns (SharedStruct.Project[] memory) {
    return allProjectsData;
  }

  // Cheer済みフラグをオンにする
  function addCheerProject(address _cheererAddress, address _projectAddress) external {
    require(!isCheer[_cheererAddress][_projectAddress], "already cheer");
    isCheer[_cheererAddress][_projectAddress] = true;
  }

  // Cheer済みフラグをオフにする
  function removeCheerProject(address _cheererAddress, address _projectAddress) external {
    require(isCheer[_cheererAddress][_projectAddress], "already not cheer");
    isCheer[_cheererAddress][_projectAddress] = false;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../shared/SharedStruct.sol";

interface ICheersData {
  function addOwnerData(
    address _daoAddress,
    string memory _daoName,
    string memory _daoProfile,
    string memory _daoIcon,
    bool _isDao
  ) external;

  function getAllDaosData() external view returns (SharedStruct.Owner[] memory);

  function addCheerData(
    address _projectAddress,
    address _owner,
    uint256 _creationTime,
    string memory _message,
    uint256 _cherAmount
  ) external;

  function getCheersDataByCheerer(address _ownerAddress) external view returns (SharedStruct.Cheer[] memory);

  function getCheersDataOfProject(address _projectAddress) external view returns (SharedStruct.Cheer[] memory);

  // PROJECT追加
  function addProject(
    address _challenger,
    address _projectAddress,
    address _belongDao,
    string memory _projectName,
    string memory _projectContent,
    string memory _projectReword
  ) external;

  // アドレスごとのProject取得
  function getProjectsDataOfChallenger(address _challenger) external view returns (SharedStruct.Project[] memory);

  // Cheer済みフラグをオンにする
  function addCheerProject(address _cheererAddress, address _projectAddress) external;

  // Cheer済みフラグをオフにする
  function removeCheerProject(address _cheererAddress, address _projectAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IProjectPool {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library SharedStruct {
  struct Owner {
    uint256 ownerCreationTime;
    address ownerAddress;
    string ownerName;
    string ownerProfile;
    string ownerIcon;
  }

  struct Project {
    uint256 projectCreationTime;
    address projectChallengerAddress;
    address projectAddress;
    address projectBelongDaoAddress;
    string projectName;
    string projectContent;
    string projectReword;
  }

  struct Cheer {
    uint256 cheerCherAmount;
    uint256 cheerCreationTime;
    address cheerProjectAddress;
    address cheerAddress;
    string cheerMessage;
  }
}