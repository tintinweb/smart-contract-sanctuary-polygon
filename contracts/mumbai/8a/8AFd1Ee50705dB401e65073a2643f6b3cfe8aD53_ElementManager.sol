//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IElementManager} from "./IElementManager.sol";

contract ElementManager is IElementManager 
//contract ElementManager
{
    uint256 nn;
    event eLog(uint256 nn,string name,uint256 value);

    Element[] public override elements;
    uint256 public override elementsId;
    // id -> index
    mapping(uint256 => uint256) public override elementsIndexes;

    uint256 public 	override sizeLimit; // DON'T CHANGE
    uint256 private 	maxElementsCount;
    uint256 private 	elementsRange;

    // DON'T CHANGE
//    constructor(uint256 _elementsToOpen,uint256 _sizeLimit,uint256 _elementsRange) 
    constructor() 
    {
    uint256 _elementsToOpen 	= 100;
    uint256 _sizeLimit 		= 10;
    uint256 _elementsRange 	= 20;

    emit eLog(nn++,"== Constructor ==",0);
    emit eLog(nn++,"_elementsToOpen",_elementsToOpen);
    emit eLog(nn++,"_sizeLimit",_sizeLimit);
    emit eLog(nn++,"_elementsRange",_elementsRange);

        require(_elementsToOpen > (_elementsRange / 2),"ElementManager::constructor: ELEMENTSRANGE_MORE_THAN_ELEMENTSTOOPEN");
        for (uint256 i; i < _elementsToOpen; i++) 
	{
            bool isClosable = ((uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, elements.length))) % 2) == 0);
	    emit eLog(nn++,"i",i);
	    emit eLog(nn++,"isClosable",isClosable?1:0);
            _openElement(isClosable);
        }

        sizeLimit = _sizeLimit;
        maxElementsCount = _elementsToOpen + (_elementsRange / 2);
        elementsRange = _elementsRange;
    }

    function getElement(uint256 _id) external view override returns (Element memory) 
    {
        return elements[elementsIndexes[_id]];
    }

    function getAllElementsLength() external view override returns (uint256) 
    {
        return elements.length;
    }

    function getAllElements() external view override returns (Element[] memory) 
    {
        return elements;
    }

    function getElementsPage(uint256 _cursor, uint256 _count)public view override returns (Element[] memory elementsPage, uint256 newCursor)
    {
        if (_cursor >= elements.length) {
            return (elementsPage, 0);
        }

        if (_cursor + _count >= elements.length) {
            _count = elements.length - _cursor;
        } else {
            newCursor = _cursor + _count;
        }

        elementsPage = new Element[](_count);
        for (uint256 i; i < _count; i++) {
            elementsPage[i] = elements[_cursor + i];
        }
    }

    function getClosableElements(uint256 _cursor, uint256 _count)external view override returns(uint256 newCursor,bool closureNeeded,uint256[] memory ids )
    {
        uint256 count;

        Element[] memory elementsPage;
        (elementsPage, newCursor) = getElementsPage(_cursor, _count);

        uint256[] memory toClose = new uint256[](sizeLimit);

        for (uint256 i; i < elementsPage.length; i++) 
	{
            if (elementsPage[i].isClosable) {
                toClose[count] = elementsPage[i].id;
                count++;

                if (count == sizeLimit) {
                    newCursor = _cursor + sizeLimit;
                    break;
                }
            }
        }

        uint256[] memory toCloseTrimmedArray = new uint256[](count);

        for (uint256 i; i < count; i++) 
	{
            toCloseTrimmedArray[i] = toClose[i];
        }

        ids = toCloseTrimmedArray;

        if (count > 0) 
	{
            closureNeeded = true;
        }
    }

    function closeElements(uint256[] memory ids) public override 
    {
	emit eLog(nn++,"func: closeElements",0);
        require(ids.length <= sizeLimit, "ElementManager::closeElements: TOO_MANY_ELEMENTS");
        for (uint256 i; i < ids.length; i++) 
	{
	    emit eLog(nn++,"get _closeElement",ids[i]);
            _closeElement(ids[i]);
        }
	emit eLog(nn++,"get _shakeElements",0);
        _shakeElements(); // DON'T CHANGE
    }

    // DON'T CHANGE
    function _shakeElements() internal 
    {
	emit eLog(nn++,"func: _shakeElements",0);
        uint256 randomUint = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, elements.length)));
	emit eLog(nn++,"randomUint",randomUint);
        uint256 delta = randomUint % elementsRange;
	emit eLog(nn++,"delta",delta);
        uint256 newElementsCount = maxElementsCount - delta;
	emit eLog(nn++,"newElementsCount",newElementsCount);
        bool needsOpen = newElementsCount > elements.length;
	emit eLog(nn++,"needsOpen:bool",needsOpen?1:0);

        uint256 count = (needsOpen ? (newElementsCount - elements.length) : (elements.length - newElementsCount));
	emit eLog(nn++,"count",count);
	emit eLog(nn++,"cicle 2 0<i<count",delta);
        for (uint256 i; i < count; i++) 
	{
	emit eLog(nn++,"i",i);
            if (needsOpen) 
	    {
                bool isClosable = ((uint256(keccak256(abi.encodePacked(block.difficulty + i, block.timestamp, elements.length))) % 2) == 0);
		emit eLog(nn++,"isClosable:bool",isClosable?1:0);
                _openElement(isClosable);
            } 
	    else 
	    {
                uint256 elementIndex = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp + i, elements.length))) % elements.length;
		emit eLog(nn++,"elementIndex",elementIndex);
                _deleteElement(elements[elementIndex].id);
            }
        }
	emit eLog(nn++,"delta",delta);
	emit eLog(nn++,"cicle 2 0<i<delta",delta);

        for (uint256 i; i < delta; i++) 
	{
	emit eLog(nn++,"i",i);
            uint256 elementIndex = uint256(keccak256(abi.encodePacked(block.difficulty + i, block.timestamp, elements.length))) % elements.length;
	    emit eLog(nn++,"elementIndex",elementIndex);
	    emit eLog(nn++,"isClosable",elements[elementIndex].isClosable?0:1);
            elements[elementIndex].isClosable = !elements[elementIndex].isClosable;
        }
    }

    function _closeElement(uint256 _id) internal 
    {
	emit eLog(nn++,"func: _closeElement",_id);
        Element storage element = elements[elementsIndexes[_id]];
        if (element.id == _id && element.isClosable) 
	{
            _deleteElement(_id);
	    emit eLog(nn++,"_deleteElement",_id);
        }
    }

    function _openElement(bool _needsClosure) internal 
    {
	emit eLog(nn++,"func: _openElement:bool",_needsClosure?1:0);
        Element memory element = Element({id: elementsId, isClosable: _needsClosure});
        elementsId++;
	emit eLog(nn++,"elements.push.id",element.id);
	emit eLog(nn++,"elements.push.isClosable",element.isClosable?1:0);
        elements.push(element);
        elementsIndexes[element.id] = elements.length - 1;
    }

    function _deleteElement(uint256 _id) internal 
    {
	emit eLog(nn++,"func: _deleteElement",_id);
        elements[elementsIndexes[_id]] = elements[elements.length - 1];
        elementsIndexes[elements[elements.length - 1].id] = elementsIndexes[_id];
        elements.pop();
	emit eLog(nn++,"delete elementsIndexes",_id);
        delete elementsIndexes[_id];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IElementManager 
{
    struct Element 
    {
        uint256 id;
        bool isClosable;
    }

    function elements(uint256 _index) external view returns (uint256 id, bool isClosable);

    function elementsId() external view returns (uint256);

    function elementsIndexes(uint256) external view returns (uint256);

    function sizeLimit() external view returns (uint256);

    function getElement(uint256 _id) external view returns (Element memory);

    function getAllElementsLength() external view returns (uint256);

    function getAllElements() external view returns (Element[] memory);

    function getElementsPage(uint256 cursor, uint256 count)external view returns (Element[] memory elementsPage, uint256 newCursor);

    function getClosableElements(uint256 _cursor, uint256 _count)external view returns (uint256 newCursor,bool closureNeeded,uint256[] memory ids);

    function closeElements(uint256[] memory ids) external;
}