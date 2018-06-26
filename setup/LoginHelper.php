<?php

namespace modules;

use Craft;
use craft\web\View;
use craft\events\TemplateEvent;

use yii\base\Event;
use yii\base\Module;

/**
 * Displays default login credentials on login pages, so it's very easy to access the control panel.
 * Only functions in dev mode, though it's not recommended by any means to actually use this outside of a local environment.
 */
class LoginHelper extends Module
{
	/**
	 * @inheritdoc
	 * @see yii\base\Module
	 */
	public function init()
	{
		parent::init();

		if (Craft::$app->getRequest()->getIsCpRequest() && Craft::$app->getConfig()->general->devMode) {
			Event::on(
				View::class,
				View::EVENT_BEFORE_RENDER_PAGE_TEMPLATE,
				function (TemplateEvent $event) {
					if (isset(Craft::$app->requestedAction)
						&& Craft::$app->requestedAction->id = 'login'
						&& is_a(Craft::$app->requestedAction->controller, craft\controllers\UsersController::class)) { // On the login page specifically, register some JS that will show the default credentials.
						Craft::$app->getView()->registerJs(<<<'EOT'
$('#password-field').after('<p class="centeralign"><code>User: admin&nbsp;&nbsp;|&nbsp;&nbsp;Pass: craftdev</code></p>');
EOT
						);
					} else { // On any other control panel page, add some JS that will inject an additional display to the session expiration dialogues.
						Craft::$app->getView()->registerJs(<<<'EOT'
(function() {
var added = false;
if (Craft && Craft.cp && Craft.cp.authManager) {
	var showLoginModal = Craft.AuthManager.prototype.showLoginModal;
	Craft.AuthManager.prototype.showLoginModal = function() {
		showLoginModal.apply(this, arguments);
		if (!added) {
			this.loginModal.$container.find('.inputcontainer').after('<p class="centeralign"><code>Pass: craftdev</code></p>');
		}
		added = true;
	};
}
})();
EOT
						);
					}
				}
			);
		}
	}
}
