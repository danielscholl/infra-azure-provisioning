'use strict';

// Imports
const should = require('chai').Should();
const { expect } = require('chai');
const request = require("supertest");
const config = require("../config");
const testUtils = require("../utils/testUtils");
const telemetryUtils = require("../utils/telemetryUtils");
const { assert } = require('console');

// Test Setup
let scenario = "seismicservice_crudOps";

const majorVersion = testUtils.between(1, 100000);
const minorVersion = testUtils.between(1, 100000);
let runId = `${majorVersion}.${minorVersion}`;

console.log(`run ID: ${runId}`);

let test = {
  runId: runId,
  scenario: scenario,
  service: "service",
  api: "api",
  expectedResponse: -1,
  failedTests: 0,
};

// Test Scenario
describe(scenario, (done) => {
  let token;

  before(done => {
    // Get a new OAuth Token
    testUtils.oAuth.post('/token')
      .set('Content-Type', 'application/x-www-form-urlencoded')
      .send(config.auth_params)
      .then(res => {
        token = 'Bearer ' + res.body.access_token;
        done();
      })
      .catch(err => {
        done(err)
      });
  });

  describe('Scenario: Seismic Service supports CRUD operations', (done) => {
    //basic health test
    if (config.test_flags.crud_seismic.getStatus) {
      it("Get Seismic Status", done => {
        test.service = testUtils.services.seismic;
        test.api = test.service.api.statusCheck;
        test.expectedResponse = test.api.expectedResponse;

        test.service.host
          .get(test.api.path)
          .set('Authorization', token)
          .set('data-partition-id', testUtils.partition)
          .expect(test.expectedResponse)
          .then(() => {
            telemetryUtils.passApiRequest(test);
            done();
          })
          .catch(err => {
            telemetryUtils.failApiRequest(test, err);
            done(err);
          });
      });
    }

    afterEach(function () {
      if (this.currentTest.state === 'failed') {
        test.failedTests += 1;
      }
    });

    after(done => {
      telemetryUtils.scenarioRequest(runId, testUtils.services.seismic, scenario, test.failedTests);
      done();
    });
  });
});