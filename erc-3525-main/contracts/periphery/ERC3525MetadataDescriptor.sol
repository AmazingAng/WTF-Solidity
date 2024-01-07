// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./interface/IERC3525MetadataDescriptor.sol";
import "../extensions/IERC3525Metadata.sol";

contract ERC3525MetadataDescriptor is IERC3525MetadataDescriptor {

    using Strings for uint256;

    function constructContractURI() external view override returns (string memory) {
        IERC3525Metadata erc3525 = IERC3525Metadata(msg.sender);
        return 
            string(
                abi.encodePacked(
                    /* solhint-disable */
                    'data:application/json;base64,',
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"', 
                            erc3525.name(),
                            '","description":"',
                            _contractDescription(),
                            '","image":"',
                            _contractImage(),
                            '","valueDecimals":"', 
                            uint256(erc3525.valueDecimals()).toString(),
                            '"}'
                        )
                    )
                    /* solhint-enable */
                )
            );
    }

    function constructSlotURI(uint256 slot_) external view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    /* solhint-disable */
                    'data:application/json;base64,',
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"', 
                            _slotName(slot_),
                            '","description":"',
                            _slotDescription(slot_),
                            '","image":"',
                            _slotImage(slot_),
                            '","properties":',
                            _slotProperties(slot_),
                            '}'
                        )
                    )
                    /* solhint-enable */
                )
            );
    }

    function constructTokenURI(uint256 tokenId_) external view override returns (string memory) {
        IERC3525Metadata erc3525 = IERC3525Metadata(msg.sender);
        return 
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            /* solhint-disable */
                            '{"name":"',
                            _tokenName(tokenId_),
                            '","description":"',
                            _tokenDescription(tokenId_),
                            '","image":"',
                            _tokenImage(tokenId_),
                            '","balance":"',
                            erc3525.balanceOf(tokenId_).toString(),
                            '","slot":"',
                            erc3525.slotOf(tokenId_).toString(),
                            '","properties":',
                            _tokenProperties(tokenId_),
                            "}"
                            /* solhint-enable */
                        )
                    )
                )
            );
    }

    function _contractDescription() internal view virtual returns (string memory) {
        return "";
    }

    function _contractImage() internal view virtual returns (bytes memory) {
        return "";
    }

    function _slotName(uint256 slot_) internal view virtual returns (string memory) {
        slot_;
        return "";
    }

    function _slotDescription(uint256 slot_) internal view virtual returns (string memory) {
        slot_;
        return "";
    }

    function _slotImage(uint256 slot_) internal view virtual returns (bytes memory) {
        slot_;
        return "";
    }

    function _slotProperties(uint256 slot_) internal view virtual returns (string memory) {
        slot_;
        return "[]";
    }

    function _tokenName(uint256 tokenId_) internal view virtual returns (string memory) {
        // solhint-disable-next-line
        return 
            string(
                abi.encodePacked(
                    IERC3525Metadata(msg.sender).name(), 
                    " #", tokenId_.toString()
                )
            );
    }

    function _tokenDescription(uint256 tokenId_) internal view virtual returns (string memory) {
        tokenId_;
        return "";
    }


    function _tokenImage(uint256 tokenId_) internal view virtual returns (bytes memory) {
        tokenId_;
        return "";
    }

    function _tokenProperties(uint256 tokenId_) internal view virtual returns (string memory) {
        tokenId_;
        return "{}";
    }
}