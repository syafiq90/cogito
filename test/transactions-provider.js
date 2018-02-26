const expect = require('chai').expect
const td = require('testdouble')
const anything = td.matchers.anything
const contains = td.matchers.contains
const { stubResponse, stubResponseError } = require('./provider-stubbing')
const Web3 = require('web3')
const CogitoProvider = require('../source/lib/cogito-provider')

describe('sending transactions', function () {
  const transaction = {
    from: '0x1234567890123456789012345678901234567890',
    gasPrice: '0x20',
    nonce: '0x30',
    gas: '0x40',
    chainId: 50
  }

  let cogitoProvider
  let originalProvider
  let telepathChannel
  let web3

  beforeEach(function () {
    originalProvider = td.object()
    telepathChannel = td.object()
    cogitoProvider = new CogitoProvider({ originalProvider, telepathChannel })
    web3 = new Web3(cogitoProvider)
  })

  context('when cogito provides signatures', function () {
    const signed = '0xSignedTransaction'

    beforeEach(function () {
      const request = { method: 'sign', params: [transaction] }
      const response = { result: signed }
      td.when(telepathChannel.send(contains(request))).thenResolve(response)
    })

    context('when using original provider for raw transactions', function () {
      const hash = '0xTransactionHash'

      beforeEach(function () {
        const sendRaw = { method: 'eth_sendRawTransaction', params: [signed] }
        stubResponse(originalProvider, contains(sendRaw), hash)
      })

      it('sends a cogito signed transaction', function (done) {
        web3.eth.sendTransaction(transaction, function (_, result) {
          try {
            expect(result).to.equal(hash)
            done()
          } catch (assertionFailure) {
            done(assertionFailure)
          }
        })
      })
    })
  })

  it('throws when signing via telepath fails', function (done) {
    td.when(telepathChannel.send(anything())).thenReject(new Error('an error'))
    web3.eth.sendTransaction(transaction, function (error, _) {
      try {
        expect(error).to.not.be.null()
        done()
      } catch (assertionFailure) {
        done(assertionFailure)
      }
    })
  })

  it('throws when cogito returns an error', function (done) {
    const response = { error: { message: 'some error', code: -42 } }
    td.when(telepathChannel.send(anything())).thenResolve(response)
    web3.eth.sendTransaction(transaction, function (error, _) {
      try {
        expect(error).to.not.be.null()
        done()
      } catch (assertionFailure) {
        done(assertionFailure)
      }
    })
  })

  it('sets transaction defaults', function (done) {
    const transactionWithDefaults = Object.assign({ value: '0x0' }, transaction)
    const expectedRequest = { method: 'sign', params: [transactionWithDefaults] }
    web3.eth.sendTransaction(transaction, function () {
      try {
        td.verify(telepathChannel.send(contains(expectedRequest)))
        done()
      } catch (assertionFailure) {
        done(assertionFailure)
      }
    })
  })

  describe('transaction nonces', function () {
    const withoutNonce = Object.assign({}, transaction)
    delete withoutNonce.nonce

    const transactionCountRequest = {
      method: 'eth_getTransactionCount',
      params: [ transaction.from, 'pending' ]
    }

    it('is equal to transaction count when not specified', function (done) {
      stubResponse(originalProvider, contains(transactionCountRequest), '0x42')
      const expectedRequest = { method: 'sign', params: [{ nonce: '0x42' }] }
      web3.eth.sendTransaction(withoutNonce, function () {
        try {
          td.verify(telepathChannel.send(contains(expectedRequest)))
          done()
        } catch (assertionFailure) {
          done(assertionFailure)
        }
      })
    })

    it('increments for pending transactions', function (done) {
      stubResponse(originalProvider, contains(transactionCountRequest), '0x42')
      web3.eth.sendTransaction(withoutNonce, function () {})
      const expectedRequest = { method: 'sign', params: [{ nonce: '0x43' }] }
      web3.eth.sendTransaction(withoutNonce, function () {
        try {
          td.verify(telepathChannel.send(contains(expectedRequest)))
          done()
        } catch (assertionFailure) {
          done(assertionFailure)
        }
      })
    })

    it('is unchanged when defined', function (done) {
      const expectedRequest = { method: 'sign', params: [transaction] }
      web3.eth.sendTransaction(transaction, function () {
        try {
          td.verify(telepathChannel.send(contains(expectedRequest)))
          done()
        } catch (assertionFailure) {
          done(assertionFailure)
        }
      })
    })

    it('throws when transaction count cannot be determined', function (done) {
      stubResponseError(originalProvider, contains(transactionCountRequest))
      web3.eth.sendTransaction(withoutNonce, function (error) {
        try {
          expect(error).to.exist()
          done()
        } catch (assertionFailure) {
          done(assertionFailure)
        }
      })
    })
  })
})
