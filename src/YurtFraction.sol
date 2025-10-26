// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title YurtFraction
/// @notice ERC20 representing fractional property shares.
/// @dev SECURITY: Single privileged owner. Owner can update metadata URI; no mint/burn beyond constructor. Not upgradeable; no reentrancy.
contract YurtFraction is ERC20, Ownable {
    /// @dev SECURITY: Mutable by owner and not validated. Treat as untrusted input; clients should sanitize and prefer HTTPS/IPFS.
    string public propertyURI;
    /// @notice Emitted on metadata URI change for auditability.
    /// @param newURI New metadata URI set by the owner.
    event PropertyURIUpdated(string newURI);

    /// @param _name Token name.
    /// @param _symbol Token symbol.
    /// @param _totalShares Total supply minted once in constructor.
    /// @param _propertyURI Initial metadata URI.
    /// @param _owner Receives full supply and admin rights.
    /// @dev SECURITY: Ensure _owner is a secure address (e.g., multisig). Supply is fixed after deployment.
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalShares,
        string memory _propertyURI,
        address _owner
    ) ERC20(_name, _symbol) Ownable(_owner) {
        propertyURI = _propertyURI;
        _mint(_owner, _totalShares);
    }

    /// @notice Update property metadata URI.
    /// @dev SECURITY: onlyOwner. No format/content checks; downstream code must not auto-execute data from this URI.
    /// @param _newURI URI string (unvalidated).
    function setPropertyURI(string calldata _newURI) external onlyOwner {
        propertyURI = _newURI;
        emit PropertyURIUpdated(_newURI);
    }
}
