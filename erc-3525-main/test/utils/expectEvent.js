const { expect } = require('chai');

function expectEvent (receipt, expectEventName, expectEventArgs = {}) {
  const logs = Object.keys(receipt.events).map(name => {
    return ({ event: receipt.events[name].event, args: receipt.events[name].args })
  })

  return inLogs(logs, expectEventName, expectEventArgs);
}

function inLogs (logs, eventName, eventArgs = {}) {
  const events = logs.filter(e => e.event === eventName);
  expect(events.length > 0).to.equal(true, `No '${eventName}' events found`);

  const exception = [];
  const event = events.find(function (e) {
    for (const [k, v] of Object.entries(eventArgs)) {
      try {
        contains(e.args, k, v);
      } catch (error) {
        exception.push(error);
        return false;
      }
    }
    return true;
  });

  if (event === undefined) {
    throw exception[0];
  }

  return event;
}

function contains (args, key, value) {
  expect(key in args).to.equal(true, `Event argument '${key}' not found`);

  if (value === null) {
    expect(args[key]).to.equal(null,
      `expected event argument '${key}' to be null but got ${args[key]}`);
  } else  {
    expect(args[key]).to.be.deep.equal(value,
      `expected event argument '${key}' to have value ${value} but got ${args[key]}`);
  }
}

module.exports = {
  expectEvent
};
