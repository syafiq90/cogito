import {
  generatePrivateKey, privateKeyToAddress, keccak256, sign, recover
} from './primitives'

export function issue (attribute, issuerKey) {
  const issuer = privateKeyToAddress(issuerKey)
  const attestationKey = generatePrivateKey()
  const attestationId = privateKeyToAddress(attestationKey)
  const issuingHash = keccak256(attestationId, attribute)
  const issuingSignature = sign(issuingHash, issuerKey)
  return ({
    issuer,
    attribute,
    attestationKey,
    issuingSignature
  })
}

export function accept (protoAttestation, subjectKey) {
  const { issuer, attribute, issuingSignature, attestationKey } = protoAttestation
  const subject = privateKeyToAddress(subjectKey)
  const subjectHash = keccak256(subject)
  const attestationSignature = sign(subjectHash, attestationKey)
  const acceptingHash = keccak256(attribute)
  const acceptingSignature = sign(acceptingHash, subjectKey)
  return ({
    issuer,
    subject,
    attribute,
    issuingSignature,
    attestationSignature,
    acceptingSignature
  })
}

export function verify (attestation) {
  const {
    issuer, subject, attribute,
    issuingSignature, attestationSignature, acceptingSignature
  } = attestation
  const subjectHash = keccak256(subject)
  const attestationId = recover(subjectHash, attestationSignature)
  const issuingHash = keccak256(attestationId, attribute)
  const acceptingHash = keccak256(attribute)
  return (
    recover(issuingHash, issuingSignature) === issuer &&
    recover(acceptingHash, acceptingSignature) === subject
  )
}