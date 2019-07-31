module.exports = ->
  @World = require("../../support/world.coffee").World

  @Given /^I am signed in, viewing a new discussion$/, (callback) ->
    @driver.get('http://localhost:3000/angular_support/setup_for_add_comment').then =>
      callback()

  @Given /^I am signed in, viewing a discussion with a comment$/, (callback) ->
    @driver.get('http://localhost:3000/angular_support/setup_for_like_comment').then =>
      callback()

  @When /^I add a comment to the discussion$/, (callback) ->
    @browser.findElement(@by.id('fake_comment_input')).click().then =>
      @browser.findElement(@by.id('comment-field')).sendKeys('I am commenting').then =>
        @browser.findElement(@by.id('post-comment-btn')).click().then =>
          callback()

  @Then /^I should see the comment has been appended to the discussion$/, (callback) ->
    message = @browser.findElement(@by.css('.comment-body')).getText().then (text) =>
      @assert.equal text, 'I am commenting'
      callback()

  @When /^I click like on the comment$/, (callback) ->
    @browser.findElement(@by.css('.like-comment-btn')).click().then =>
      callback()

  @Then /^the like button should say 'Unlike'$/, (callback) ->
    @browser.findElement(@by.css('.unlike-comment-btn')).getText().then (text)=>
      @assert.equal text, 'Unlike'
      callback()

  @Then /^I should see that I have liked the comment$/, (callback) ->
    @browser.findElement(@by.css('.liked-by')).getText().then (text)=>
      @assert.equal text, 'Liked by You'
      callback()

    #@browser.get('http://localhost:8000/discussions/1').then ->
      #done()

  #@When /^I add a comment to the discussion$/, (callback) ->
    #el = @browser.findElement(@by.tagName 'input')
    #el.clear
    #el.sendKeys('Yo wassup').then ->
      #callback()

  #@Then /^I should see the comment has been appended to the discussion$/, (callback) ->
    #@browser.findElement(@by.tagName 'span').getText().then (text) =>
      #@assert.equal text, 'Yo wassup'
      #callback()
