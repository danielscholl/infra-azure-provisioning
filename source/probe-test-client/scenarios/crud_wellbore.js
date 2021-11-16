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
let scenario = "wellboreservice_crudOps";

const majorVersion = testUtils.between(1, 100000);
const minorVersion = testUtils.between(1, 100000);
let runId = `${majorVersion}.${minorVersion}`;

console.log(`run ID: ${runId}`);

const sampleLogCreate = require(`${__dirname}/../testData/sample_create_log.json`);
const sampleLogData = require(`${__dirname}/../testData/sample_log_data.json`);
const sampleLogQuery = {
  "query": "string"
};


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

  describe('Scenario: Wellbore Service supports CRUD operations', (done) => {
    //basic health check
    if (config.test_flags.crud_wellbore.getHealth) {
      it("Get Wellbore Health", done => {
        test.service = testUtils.services.wellbore;
        test.api = test.service.api.healthCheck;
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
    //setup for upload
    if (config.test_flags.crud_wellbore.createLog) {
      it("Create Log", done => {
        test.service = testUtils.services.wellbore;
        test.api = test.service.api.createLog;
        test.expectedResponse = test.api.expectedResponse;

        test.service.host
          .post(test.api.path)
          .set('Authorization', token)
          .set('Content-Type', 'application/json')
          .set('data-partition-id', testUtils.partition)
          .send(sampleLogCreate)
          .expect(test.expectedResponse)
          .then(res => {
            telemetryUtils.passApiRequest(test);
            done();
          })
          .catch(err => {
            telemetryUtils.failApiRequest(test, err);
            done(err)
          });
      });
    }
    //uploads and stores data testing storage
    if (config.test_flags.crud_wellbore.uploadData) {
      it("Test Wellbore Storage", done => {
        test.service = testUtils.services.wellbore;
        test.api = test.service.api.createLog;
        test.expectedResponse = test.api.expectedResponse;

        test.service.host
          .post(test.api.path + "/opendes:log:myLog_GR/" + "data")
          .set('Authorization', token)
          .set('Content-Type', 'application/json')
          .set('data-partition-id', testUtils.partition)
          .send(sampleLogData)
          .expect(test.expectedResponse)
          .then(res => {
            telemetryUtils.passApiRequest(test);
            done();
          })
          .catch(err => {
            telemetryUtils.failApiRequest(test, err);
            done(err)
          });
      });
    }
    //uses search service 
    if (config.test_flags.crud_wellbore.searchLogs) {
      it("Test Wellbore Search", done => {
        test.service = testUtils.services.wellbore;
        test.api = test.service.api.searchLogs;
        test.expectedResponse = test.api.expectedResponse;

        test.service.host
          .post(test.api.path)
          .set('Authorization', token)
          .set('Content-Type', 'application/json')
          .set('data-partition-id', testUtils.partition)
          .expect(test.expectedResponse)
          .send(sampleLogQuery)
          .then(res => {
            telemetryUtils.passApiRequest(test);
            done();
          })
          .catch(err => {
            telemetryUtils.failApiRequest(test, err);
            done(err)
          });
      });
    }

    afterEach(function () {
      if (this.currentTest.state === 'failed') {
        test.failedTests += 1;
      }
    });

    after(done => {
      telemetryUtils.scenarioRequest(runId, testUtils.services.wellbore, scenario, test.failedTests);
      done();
    });
  });
});