import React from 'react'
import glamorous from 'glamorous'
import { Button } from 'semantic-ui-react'
import QRCode from 'qrcode.react'
import { WithStore } from '@react-frontend-developer/react-redux-render-prop'
import {
  Centered, DistributedHorizontally, FullWidthCentered, ValueWrapper
} from '@react-frontend-developer/react-layout-helpers'

export const CogitoAttestations = () => (
  <FullWidthCentered>
    <P>
      Cogito can store attestations, which are claims about your identity.
    </P>
    <Div>
      <DistributedHorizontally>
        <ShowAttestation />
        <RetrieveAttestation />
      </DistributedHorizontally>
    </Div>
  </FullWidthCentered>
)

const ShowAttestation = () => (
  <Centered>
    <p>Scan to add a dummy attestation:</p>
    <QRCode
      value='https://cogito.example.com/attestations/receive#A=dummy%3Ahello%20world'
    />
  </Centered>
)

const RetrieveAttestation = () => (
  <WithStore selector={state => ({ attestation: state.attestations.retrieved })}>
    {
      ({ attestation }) =>
        <Centered>
          Your attestation is:
          <ValueWrapper>{attestation || 'unknown'}</ValueWrapper>
          <Button basic color='pink'>Retrieve</Button>
        </Centered>
    }
  </WithStore>
)

const P = glamorous.p({
  maxWidth: '40rem'
})

const Div = glamorous.div({
  width: '40rem'
})