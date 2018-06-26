<?php

namespace modules;

use Craft;
use craft\events\RegisterCpNavItemsEvent;
use craft\Events\RegisterUrlRulesEvent;
use craft\events\TemplateEvent;
use craft\web\Controller;
use craft\web\UrlManager;
use craft\web\View;
use craft\web\twig\variables\Cp;

use yii\base\Event;
use yii\base\Module;

/**
 * Adds a section to the control panel that allows a user to evaluate raw PHP. Allows for quick running of copied
 * error demonstration code, test snippets, weird one-off cases, and destroying the entire site.
 * Really, even though this only works in dev mode, be _very_ careful with it, and please don't deploy this to any
 * publically-facing stes.
 */
class EvalHelper extends Module
{
	/**
	 * @inheritdoc
	 * @see yii\base\Module
	 */
	public function init()
	{
		parent::init();

		if (Craft::$app->getConfig()->general->devMode && Craft::$app->getUser()->getIsAdmin()) {

			Event::on(
				UrlManager::class,
				UrlManager::EVENT_REGISTER_SITE_URL_RULES,
				function (RegisterUrlRulesEvent $event) {
					$event->rules['eval'] = ['route' => 'eval/eval'];
				}
			);

			Craft::$app->controllerMap['eval'] = '\modules\EvalController';

			if (Craft::$app->getRequest()->getIsCpRequest()) {

				Event::on(
					View::class,
					View::EVENT_BEFORE_RENDER_PAGE_TEMPLATE,
					function (TemplateEvent $event) {
						Craft::$app->getView()->registerJs(<<<'EOT'
(function() {
var specialMenuItem = $('#nav-special-eval-menu a');
specialMenuItem.attr('href', '');
specialMenuItem.on('click', function(e) {
	e.preventDefault();
	var modalFrame = $('<div id="special-eval-modal" class="modal alert fitted"/>');
	var modalContents = $('<div class="body" style="overflow: auto; height: 100%;"/>').appendTo(modalFrame);
	$('<p><b>Evaluate Raw PHP</b></p>').appendTo(modalContents);
	$('<p>Whatever arbitrary PHP entered here will be evaluated on the server with access to Craft.<br>Please use this responsibly, for running quick test cases or other similar one-off tasks.</p>').appendTo(modalContents);
	Craft.ui.createTextarea({
		rows: 8,
		cols: 80,
		id: 'special-eval-value',
		name: 'special-eval',
		autofocus: true,
		placeholder: 'PHP to Evaluate',
	}).appendTo(modalContents);
	var modal = new Garnish.Modal(modalFrame);
	$('<input type="submit" class="btn submit" value="Run it"/>')
		.appendTo($('<div class="buttons"/>')
			.appendTo(modalContents))
		.on('click', function() {
			var dataToSend = {};
			dataToSend.script = $('#special-eval-value').val();
			dataToSend[Craft.csrfTokenName] = Craft.csrfTokenValue;
			$.post('/eval', dataToSend)
				.done(function(result) {
					modalContents.empty();
					console.log(result);
					$('<code style="overflow: scroll;"/>').appendTo(modalContents).append($('<pre/>').text(result));
					$('<input type="submit" class="btn submit" value="Done"/>')
						.appendTo($('<div class="buttons"/>')
							.appendTo(modalContents))
						.on('click', modal.hide.bind(modal));
					modal.updateSizeAndPosition();
				})
				.fail(function(err) {
					modalContents.empty();
					console.log(err);
					$('<p class="warning"/>').appendTo(modalContents).text('The server failed to evaluate the script');
					$('<code style="overflow: scroll;"/>').appendTo(modalContents).html(err.responseText);
					$('<input type="submit" class="btn submit" value="Done"/>')
						.appendTo($('<div class="buttons"/>')
							.appendTo(modalContents))
						.on('click', modal.hide.bind(modal));
					modal.updateSizeAndPosition();
				});
			modalFrame.removeClass('alert');
			modalContents.empty();
			modalContents.append('<div class="spinner"/>');
			modal.updateSizeAndPosition();
		});
	modal.on('fadeOut', function() {
		modal.$shade.remove();
		modal.destroy();
	});
	return false;
});
})();
EOT
						);
					}
				);
			}

			Event::on(
				Cp::class,
				Cp::EVENT_REGISTER_CP_NAV_ITEMS,
				function (RegisterCpNavItemsEvent $event) {
					$event->navItems[] = [
						'url' => '#special-eval-menu',
						'label' => 'PHP eval()',
						'fontIcon' => 'alert'
					];
				}
			);
		}
	}
}

class EvalController extends Controller
{
	public function actionEval()
	{
		$script = Craft::$app->getRequest()->getRequiredBodyParam('script');
		header('Content-Type: text/plain');
		eval($script);
		die();
	}
}